import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../navigation/app_route.dart';
import '../providers/auth_flow_provider.dart';
import '../providers/navigation_provider.dart';
import '../utils/subscription_guard.dart';
import '../theme/app_theme.dart';
import '../widgets/nav_card.dart';
import '../services/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // AuthWrapper already verified subscription before showing HomePage.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthFlowProvider>().loadGoogleUserFlag();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authFlow = context.watch<AuthFlowProvider>();
    final currentUser = authFlow.user;
    final isGoogleUser = authFlow.isGoogleUser;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Color(0xFFF8E8D0), // Cream/beige background color
      drawer: _buildProfileDrawer(currentUser, isGoogleUser),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildWelcomeMessage(context, currentUser),
                      const SizedBox(height: 24),
                      _buildFounderSection(),
                      const SizedBox(height: 24),
                      _buildNavigationSection(context),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final user = context.watch<AuthFlowProvider>().user;
    final displayName = user?.displayName ?? 'User';
    final photoUrl = user?.photoURL;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF9A826), // Amber/orange starting color
            Color(0xFFFF8C00), // Darker orange ending color
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo image
          Image.asset(
            'assets/images/icon.png',
            height: 40,
            fit: BoxFit.contain,
          ),
          Row(
            children: [
              // User avatar with tooltip
              Tooltip(
                message: displayName,
                child: CircleAvatar(
                  radius: 18,
                backgroundColor: Colors.white,
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                  style: GoogleFonts.roboto(
                            color: Color(0xFF8B4513),
                    fontWeight: FontWeight.bold,
                            fontSize: 16,
                  ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              // Menu button (3 dots)
              IconButton(
                onPressed: () async {
                  await context.read<AuthFlowProvider>().loadGoogleUserFlag();
                  _scaffoldKey.currentState?.openDrawer();
                },
                icon: Icon(
                  Icons.more_vert,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDrawer(user, bool isGoogleUser) {
    final displayName = user?.displayName ?? 'User';
    final email = user?.email ?? 'No email';
    final photoUrl = user?.photoURL;
    
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFF9A826),
                    Color(0xFFFF8C00),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null
                        ? Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                            style: GoogleFonts.roboto(
                              color: Color(0xFF8B4513),
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: GoogleFonts.roboto(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isGoogleUser ? 'Google User' : 'Email User',
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.person,
                    title: 'Profile',
                    onTap: () => _onProtectedAction(() async {
                      Navigator.pop(context);
                      _showProfileDialog();
                    }),
                  ),
                  if (!isGoogleUser) // Show password change only for email users
                    _buildDrawerItem(
                      icon: Icons.lock,
                      title: 'Change Password',
                      onTap: () => _onProtectedAction(() async {
                        Navigator.pop(context);
                        _showChangePasswordDialog();
                      }),
                    ),
                  _buildDrawerItem(
                    icon: Icons.card_membership,
                    title: 'Subscription',
                    onTap: () => _onProtectedAction(() async {
                      Navigator.pop(context);
                      final cancelled = await context
                          .read<NavigationProvider>()
                          .push<bool>(AppRoute.subscription);
                      if (cancelled == true && context.mounted) {
                        await context.read<AuthFlowProvider>().refreshSubscription();
                      }
                    }),
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings,
                    title: 'Settings',
                    onTap: () => _onProtectedAction(() async {
                      Navigator.pop(context);
                      _showComingSoonMessage('Settings');
                    }),
                  ),
                  _buildDrawerItem(
                    icon: Icons.help,
                    title: 'Help & Support',
                    onTap: () => _onProtectedAction(() async {
                      Navigator.pop(context);
                      _showComingSoonMessage('Help & Support');
                    }),
                  ),
                  _buildDrawerItem(
                    icon: Icons.info,
                    title: 'About',
                    onTap: () => _onProtectedAction(() async {
                      Navigator.pop(context);
                      _showAboutDialog();
                    }),
                  ),
                  _buildDrawerItem(
                    icon: Icons.star,
                    title: 'Rate App',
                    onTap: () => _onProtectedAction(() async {
                      Navigator.pop(context);
                      _showComingSoonMessage('Rate App');
                    }),
                  ),
                  _buildDrawerItem(
                    icon: Icons.share,
                    title: 'Share App',
                    onTap: () => _onProtectedAction(() async {
                      Navigator.pop(context);
                      _showComingSoonMessage('Share App');
                    }),
                  ),
                  const Divider(),
                  _buildDrawerItem(
                    icon: Icons.logout,
                    title: 'Sign Out',
                    onTap: () {
                      Navigator.pop(context);
                      _handleLogout();
                    },
                    textColor: Colors.red,
                    iconColor: Colors.red,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? Color(0xFF8B4513),
        size: 24,
      ),
      title: Text(
        title,
        style: GoogleFonts.roboto(
          color: textColor ?? Color(0xFF2D3748),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildWelcomeMessage(BuildContext context, user) {
    final displayName = user?.displayName ?? 'Friend';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.red,
            Colors.red,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to Your Journey, $displayName!',
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Explore activities and resources to nurture self-love and emotional intelligence.',
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              SubscriptionGuard.pushIfActive(context, AppRoute.game);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text('Get Started', style: GoogleFonts.roboto()),
          ),
        ],
      ),
    );
  }

  Widget _buildFounderSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              'assets/images/author.png',
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'From Our Founder',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B4513),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Inspiring children to embrace self-love and emotional intelligence through creative activities and positive reinforcement.',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: AppTheme.textLightColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Explore Activities',
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8B4513),
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: [
        NavCard(
          title: 'Read Books',
              description: 'Inspiring stories for kids',
          iconData: Icons.book,
              backgroundColor: Color(0xFF8B4513).withValues(alpha: 0.1),
              iconColor: Color(0xFF8B4513),
          onTap: () {
            SubscriptionGuard.pushIfActive(context, AppRoute.readBooks);
          },
        ),
        const SizedBox(height: 16),
        NavCard(
          title: 'Affirmations',
          description: 'Daily self-love affirmations',
          iconData: Icons.favorite,
          backgroundColor: Color(0xFFFF6B6B).withValues(alpha: 0.1),
          iconColor: Color(0xFFFF6B6B),
          onTap: () {
            SubscriptionGuard.pushIfActive(context, AppRoute.affirmation);
          },
        ),
        const SizedBox(height: 16),
        NavCard(
              title: 'Interactive Games',
              description: 'Fun learning activities',
              iconData: Icons.games,
              backgroundColor: Color(0xFFF9A826).withValues(alpha: 0.1),
              iconColor: Color(0xFFF9A826),
          onTap: () {
            SubscriptionGuard.pushIfActive(context, AppRoute.game);
          },
        ),
        const SizedBox(height: 16),
        NavCard(
              title: 'Daily Tasks',
              description: 'Building positive habits',
              iconData: Icons.task_alt,
              backgroundColor: Color(0xFF4CAF50).withValues(alpha: 0.1),
              iconColor: Color(0xFF4CAF50),
          onTap: () {
            SubscriptionGuard.pushIfActive(context, AppRoute.tasks);
          },
            ),
            const SizedBox(height: 16),
            NavCard(
              title: 'Shop Products',
              description: 'Educational materials',
              iconData: Icons.shopping_bag,
              backgroundColor: Color(0xFF9C27B0).withValues(alpha: 0.1),
              iconColor: Color(0xFF9C27B0),
              onTap: () {
                SubscriptionGuard.pushIfActive(context, AppRoute.product);
              },
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _onProtectedAction(FutureOr<void> Function() action) async {
    if (!await SubscriptionGuard.ensureActive(context)) return;
    await action();
  }

  void _showProfileDialog() {
    final user = context.read<AuthFlowProvider>().user;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Profile Information', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (user?.photoURL != null)
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(user!.photoURL!),
                  ),
                ),
              SizedBox(height: 16),
              _buildInfoRow('Name', user?.displayName ?? 'Not provided'),
              _buildInfoRow('Email', user?.email ?? 'Not provided'),
              _buildInfoRow(
                'Account Type',
                context.read<AuthFlowProvider>().isGoogleUser
                    ? 'Google Account'
                    : 'Email Account',
              ),
              _buildInfoRow('Member Since', user?.metadata.creationTime?.toString().split(' ').first ?? 'Unknown'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: GoogleFonts.roboto(color: Color(0xFF8B4513))),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: GoogleFonts.roboto(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.roboto(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Change Password', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: currentPasswordController,
                      obscureText: obscureCurrentPassword,
                      style: GoogleFonts.roboto(),
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        labelStyle: GoogleFonts.roboto(),
                        prefixIcon: Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(obscureCurrentPassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => obscureCurrentPassword = !obscureCurrentPassword),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your current password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: obscureNewPassword,
                      style: GoogleFonts.roboto(),
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        labelStyle: GoogleFonts.roboto(),
                        prefixIcon: Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(obscureNewPassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => obscureNewPassword = !obscureNewPassword),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a new password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirmPassword,
                      style: GoogleFonts.roboto(),
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        labelStyle: GoogleFonts.roboto(),
                        prefixIcon: Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => obscureConfirmPassword = !obscureConfirmPassword),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your new password';
                        }
                        if (value != newPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  child: Text('Cancel', style: GoogleFonts.roboto()),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    if (formKey.currentState!.validate()) {
                      setState(() => isLoading = true);
                      try {
                        await _authService.changePassword(
                          currentPasswordController.text,
                          newPasswordController.text,
                        );
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Password changed successfully!', style: GoogleFonts.roboto()),
                            backgroundColor: Color(0xFF4CAF50),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString(), style: GoogleFonts.roboto()),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } finally {
                        setState(() => isLoading = false);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF8B4513),
                    foregroundColor: Colors.white,
                  ),
                  child: isLoading
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Change Password', style: GoogleFonts.roboto()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('About Say It Now Self Love Kids', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Version 1.0.0',
                style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                'Say It Now Self Love Kids is an app designed to help children develop self-love, confidence, and emotional intelligence through interactive activities, inspiring stories, and positive reinforcement.',
                style: GoogleFonts.roboto(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 12),
              Text(
                'Created with ❤️ for children\'s emotional well-being.',
                style: GoogleFonts.roboto(fontSize: 14, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: GoogleFonts.roboto(color: Color(0xFF8B4513))),
            ),
          ],
        );
      },
    );
  }

  void _showComingSoonMessage(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!', style: GoogleFonts.roboto()),
        backgroundColor: Color(0xFF8B4513),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _handleLogout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Sign Out', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
          content: Text(
            'Are you sure you want to sign out?', 
            style: GoogleFonts.roboto(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: GoogleFonts.roboto()),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                
                // Show a simple snackbar instead of blocking dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 16),
                        Text('Signing out...', style: GoogleFonts.roboto()),
                      ],
                    ),
                    backgroundColor: Color(0xFF8B4513),
                    duration: Duration(seconds: 2),
                  ),
                );
                
                try {
                  await _authService.signOut();
                  // AuthWrapper will automatically handle navigation to login page
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error signing out: ${e.toString()}', style: GoogleFonts.roboto()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Sign Out', style: GoogleFonts.roboto()),
            ),
          ],
        );
      },
    );
  }
}