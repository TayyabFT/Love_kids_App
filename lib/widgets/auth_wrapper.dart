import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_flow_provider.dart';
import '../screens/home_page.dart';
import '../screens/landing_page.dart';

/// Root view: renders the correct screen based on [AuthFlowProvider] state.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  static const String _logTag = 'SUB_NAV';

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthFlowProvider>(
      builder: (context, authFlow, _) {
        final screen = _screenName(authFlow);
        print(
          '[$_logTag] AuthWrapper REBUILD → $screen '
          '(hasActive=${authFlow.hasActiveSubscription} '
          'subLoading=${authFlow.isSubscriptionLoading} '
          'authenticated=${authFlow.isAuthenticated})',
        );
        return _buildScreen(authFlow);
      },
    );
  }

  String _screenName(AuthFlowProvider authFlow) {
    if (authFlow.isAuthLoading) {
      return 'LoadingScaffold';
    }
    if (!authFlow.isAuthenticated) {
      return 'LandingPage';
    }
    if (authFlow.isSubscriptionLoading || authFlow.hasActiveSubscription == null) {
      return 'LoadingScaffold';
    }
    if (authFlow.hasActiveSubscription != true) {
      return 'LandingPage';
    }
    return 'HomePage';
  }

  Widget _buildScreen(AuthFlowProvider authFlow) {
    if (authFlow.isAuthLoading) {
      return const _LoadingScaffold();
    }

    if (!authFlow.isAuthenticated) {
      return const LandingPage();
    }

    // Block UI until the first subscription resolve completes. Also keep loading
    // while isSubscriptionLoading so stale logout `false` cannot flash LandingPage.
    if (authFlow.isSubscriptionLoading || authFlow.hasActiveSubscription == null) {
      return const _LoadingScaffold();
    }

    if (authFlow.hasActiveSubscription == true) {
      return const HomePage(key: ValueKey('auth-home'));
    }

    print('[$_logTag] AuthWrapper → LandingPage opened (subscription inactive)');
    return const LandingPage(key: ValueKey('auth-landing'));
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF8E8D0),
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
        ),
      ),
    );
  }
}
