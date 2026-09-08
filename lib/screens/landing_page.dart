import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../navigation/app_route.dart';
import '../providers/auth_flow_provider.dart';
import '../providers/landing_flow_provider.dart';
import '../providers/navigation_provider.dart';
import '../services/stripe_service.dart';
import '../theme/app_theme.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LandingFlowProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final landing = context.watch<LandingFlowProvider>();
    final currentUser = landing.currentUser;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Color(0xFFF8E8D0), // Cream/beige background color
      drawer: currentUser != null ? _buildProfileDrawer(landing) : null,
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
                      _buildWelcomeSection(),
                      const SizedBox(height: 24),
                      _buildSubscriptionSection(context),
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
    final user = context.watch<LandingFlowProvider>().currentUser;

    // If user is not logged in, show login/signup buttons
    if (user == null) {
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
                OutlinedButton(
                  onPressed: () {
                    context.read<NavigationProvider>().push(AppRoute.login);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white),
                    textStyle: AppTheme.roboto(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  child: const Text('Login'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    context.read<NavigationProvider>().push(AppRoute.signup);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF8B4513),
                    foregroundColor: Colors.white,
                    textStyle: AppTheme.roboto(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  child: const Text('Sign Up'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // If user is logged in, show home page style header
    final displayName = user.displayName ?? 'User';
    final photoUrl = user.photoURL;

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
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl) : null,
                  child:
                      photoUrl == null
                          ? Text(
                            displayName.isNotEmpty
                                ? displayName[0].toUpperCase()
                                : 'U',
                            style: AppTheme.roboto(
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
                  await context.read<LandingFlowProvider>().refreshUser();
                  _scaffoldKey.currentState?.openDrawer();
                },
                icon: Icon(Icons.more_vert, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDrawer(LandingFlowProvider landing) {
    final user = landing.currentUser;
    if (user == null) return SizedBox.shrink();

    final displayName = user.displayName ?? 'User';
    final email = user.email ?? 'No email';
    final photoUrl = user.photoURL;

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
                  colors: [Color(0xFFF9A826), Color(0xFFFF8C00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        photoUrl != null ? NetworkImage(photoUrl) : null,
                    child:
                        photoUrl == null
                            ? Text(
                              displayName.isNotEmpty
                                  ? displayName[0].toUpperCase()
                                  : 'U',
                              style: AppTheme.roboto(
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
                    style: AppTheme.roboto(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    email,
                    style: AppTheme.roboto(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Menu items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: Icon(Icons.person, color: Color(0xFF8B4513)),
                    title: Text('Profile', style: AppTheme.roboto()),
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to profile screen
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.payment, color: Color(0xFF8B4513)),
                    title: Text('Subscription', style: AppTheme.roboto()),
                    onTap: () {
                      Navigator.pop(context);
                      context.read<NavigationProvider>().push(AppRoute.subscription);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.history, color: Color(0xFF8B4513)),
                    title: Text('Payment History', style: AppTheme.roboto()),
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to payment history
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.help, color: Color(0xFF8B4513)),
                    title: Text('Help & Support', style: AppTheme.roboto()),
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to help
                    },
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text(
                      'Sign Out',
                      style: AppTheme.roboto(color: Colors.red),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await context.read<AuthFlowProvider>().signOut();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusDefault),
            child: Image.asset(
              'assets/images/landingpage.png',
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Say It Now Self-Love Kids App',
            style: AppTheme.roboto(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B4513),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Join us in building emotional intelligence and confidence through play and learning',
            style: AppTheme.roboto(
              fontSize: 16,
              color: AppTheme.textLightColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSubscriptionSection(BuildContext context) {
    final isProcessingPayment = context.watch<LandingFlowProvider>().isProcessingPayment;
    final monthlyPlan = StripeService.getMonthlyPlan();
    final yearlyPlan = StripeService.getYearlyPlan();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Your Plan',
            style: AppTheme.roboto(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B4513),
            ),
          ),
          /*
          const SizedBox(height: 8),
          // Test mode indicator - HIDDEN/COMMENTED OUT
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'TEST MODE: Use card 4242424242424242 for testing',
                    style: AppTheme.roboto(
                      fontSize: 12,
                      color: Colors.blue[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
          */
          const SizedBox(height: 16),

          // Monthly Plan
          _buildPlanCard(
            plan: monthlyPlan,
            isHighlighted: false,
            isProcessingPayment: isProcessingPayment,
            onTap: () => _selectPlan(context, monthlyPlan),
          ),

          const SizedBox(height: 16),

          // Yearly Plan (Highlighted)
          _buildPlanCard(
            plan: yearlyPlan,
            isHighlighted: true,
            isProcessingPayment: isProcessingPayment,
            onTap: () => _selectPlan(context, yearlyPlan),
          ),
          
        ],
      ),
    );
  }


  Future<void> _selectPlan(
    BuildContext context,
    Map<String, dynamic> plan,
  ) async {
    final landing = context.read<LandingFlowProvider>();
    final authFlow = context.read<AuthFlowProvider>();

    if (landing.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please login to subscribe to a plan',
            style: AppTheme.roboto(),
          ),
        ),
      );
      return;
    }

    final success = await landing.purchasePlan(plan);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payment successful! Welcome to Say It Now Self-Love Kids!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      await authFlow.refreshSubscription();
      // AuthWrapper switches to HomePage automatically when subscription is active.
    } else if (landing.lastPaymentError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(landing.lastPaymentError!, style: AppTheme.roboto()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPlanCard({
    required Map<String, dynamic> plan,
    required bool isHighlighted,
    required bool isProcessingPayment,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient:
            isHighlighted
                ? LinearGradient(
                  colors: [Color(0xFFF9A826), Color(0xFFFF8C00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                : null,
        color: isHighlighted ? null : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? Colors.transparent : Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isProcessingPayment ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      plan['title'],
                      style: AppTheme.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isHighlighted ? Colors.white : Color(0xFF8B4513),
                      ),
                    ),
                    if (isHighlighted)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'BEST VALUE',
                          style: AppTheme.roboto(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B4513),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      plan['priceDisplay'],
                      style: AppTheme.roboto(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isHighlighted ? Colors.white : Color(0xFF8B4513),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      plan['billingPeriod'],
                      style: AppTheme.roboto(
                        fontSize: 14,
                        color:
                            isHighlighted
                                ? Colors.white.withValues(alpha: 0.9)
                                : AppTheme.textLightColor,
                      ),
                    ),
                  ],
                ),
                if (plan['savings'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    plan['savings'],
                    style: AppTheme.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isHighlighted ? Colors.white : Colors.green[600],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                ...plan['features']
                    .map<Widget>(
                      (feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check,
                              size: 16,
                              color:
                                  isHighlighted
                                      ? Colors.white
                                      : Color(0xFF8B4513),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                feature,
                                style: AppTheme.roboto(
                                  fontSize: 14,
                                  color:
                                      isHighlighted
                                          ? Colors.white.withValues(alpha: 0.9)
                                          : AppTheme.textLightColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isProcessingPayment ? null : onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isHighlighted ? Colors.white : Color(0xFF8B4513),
                      foregroundColor:
                          isHighlighted ? Color(0xFF8B4513) : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        isProcessingPayment
                            ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isHighlighted
                                      ? Color(0xFF8B4513)
                                      : Colors.white,
                                ),
                              ),
                            )
                            : Text(
                              'Choose Plan',
                              style: AppTheme.roboto(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Duplicate _selectPlan removed.
}
