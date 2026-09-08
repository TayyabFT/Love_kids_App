import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../navigation/app_route.dart';
import '../providers/navigation_provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is already logged in
    /* 
    // Removed auto-redirect to stay compliant with new flow
    if (_authService.currentUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/home');
      });
    }
    */

    return Scaffold(
      backgroundColor: Color(0xFFF8E8D0), // Cream/beige background color
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF8B4513)),
          onPressed: () => context.read<NavigationProvider>().pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildLoginForm(),
                    const SizedBox(height: 16),
                    _buildForgotPassword(),
                    const SizedBox(height: 24),
                    _buildLoginButton(),
                    const SizedBox(height: 16),
                    _buildDivider(),
                    const SizedBox(height: 16),
                    _buildGoogleSignInButton(),
                    const SizedBox(height: 24),
                    _buildSignUpLink(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo image
        Image.asset(
          'assets/images/icon.png', // Update this path to your actual logo image path
          height: 70, // Adjust height as needed
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 24),
        Text(
          'Welcome Back!',
          style: AppTheme.roboto(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8B4513), // Brown color from website
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Log in to continue your self-love journey',
          style: AppTheme.roboto(
            fontSize: 16,
            color: AppTheme.textLightColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Email',
            style: AppTheme.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8B4513), // Brown color from website
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: AppTheme.roboto(),
            decoration: InputDecoration(
              hintText: 'Enter your email',
              hintStyle: AppTheme.roboto(color: Colors.grey),
              prefixIcon: Icon(
                Icons.email_outlined,
                color: Color(0xFFF9A826),
              ), // Orange color from header
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Color(0xFFF9A826),
                  width: 2,
                ), // Orange color from header
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Password',
            style: AppTheme.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8B4513), // Brown color from website
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: AppTheme.roboto(),
            decoration: InputDecoration(
              hintText: 'Enter your password',
              hintStyle: AppTheme.roboto(color: Colors.grey),
              prefixIcon: Icon(
                Icons.lock_outline,
                color: Color(0xFFF9A826),
              ), // Orange color from header
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Color(0xFFF9A826),
                  width: 2,
                ), // Orange color from header
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _handleForgotPassword,
        child: Text(
          'Forgot Password?',
          style: AppTheme.roboto(
            color: Color(0xFFF9A826), // Orange color from header
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleLogin,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Color(0xFF8B4513), // Brown color like CALL NOW button
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child:
          _isLoading
              ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
              : Text(
                'Login',
                style: AppTheme.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: AppTheme.roboto(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300)),
      ],
    );
  }

  Widget _buildGoogleSignInButton() {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _handleGoogleSignIn,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Image.asset(
        'assets/social/google.png', // Updated to use the correct Google icon
        height: 20,
        width: 20,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.login, color: Color(0xFF8B4513));
        },
      ),
      label: Text(
        'Continue with Google',
        style: AppTheme.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF8B4513),
        ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Don\'t have an account? ',
          style: AppTheme.roboto(color: AppTheme.textLightColor),
        ),
        GestureDetector(
          onTap: () {
            context.read<NavigationProvider>().pushReplacement(AppRoute.signup);
          },
          child: Text(
            'Sign Up',
            style: AppTheme.roboto(
              color: Color(0xFFF9A826), // Orange color from header
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _authService.signInWithEmailPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // Update last login time
        await _authService.updateLastLogin();

        // Navigation will be handled by AuthWrapper
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Login successful! checking subscription...',
                style: AppTheme.roboto(),
              ),
              backgroundColor: Color(0xFF8B4513),
              duration: Duration(seconds: 1),
            ),
          );

          // Pop everything until we are back at the root (AuthWrapper)
          context.read<NavigationProvider>().popUntilRoot();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString(), style: AppTheme.roboto()),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await _authService.signInWithGoogle();

      if (userCredential != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Google sign-in successful! Checking subscription...',
              style: AppTheme.roboto(),
            ),
            backgroundColor: Color(0xFF8B4513),
            duration: Duration(seconds: 1),
          ),
        );

        // Pop everything until we are back at the root (AuthWrapper)
        context.read<NavigationProvider>().popUntilRoot();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString(), style: AppTheme.roboto()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleForgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter your email address first',
            style: AppTheme.roboto(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _authService.resetPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Password reset email sent!',
              style: AppTheme.roboto(),
            ),
            backgroundColor: Color(0xFF8B4513),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString(), style: AppTheme.roboto()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
