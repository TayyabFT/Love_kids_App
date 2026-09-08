import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_flow_provider.dart';
import '../utils/subscription_guard.dart';

/// Wraps premium screens so expired subscriptions redirect to choose plan.
class SubscriptionProtectedScreen extends StatefulWidget {
  final Widget child;

  const SubscriptionProtectedScreen({super.key, required this.child});

  @override
  State<SubscriptionProtectedScreen> createState() =>
      _SubscriptionProtectedScreenState();
}

class _SubscriptionProtectedScreenState extends State<SubscriptionProtectedScreen>
    with WidgetsBindingObserver {
  AuthFlowProvider? _authFlow;
  bool _verifiedOnOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _verifyAccessOnce());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authFlow = context.read<AuthFlowProvider>();
    if (_authFlow != authFlow) {
      _authFlow?.removeListener(_onAuthFlowChanged);
      _authFlow = authFlow;
      _authFlow!.addListener(_onAuthFlowChanged);
    }
  }

  @override
  void dispose() {
    _authFlow?.removeListener(_onAuthFlowChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _verifyAccess();
    }
  }

  void _onAuthFlowChanged() {
    if (!mounted || _authFlow == null) return;
    if (!_authFlow!.isAuthenticated) return;
    if (_authFlow!.isSubscriptionLoading) return;
    if (_authFlow!.hasActiveSubscription != false) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        SubscriptionGuard.redirectToChoosePlan(
          context,
          reason: 'protected-screen-inactive',
        );
      }
    });
  }

  Future<void> _verifyAccessOnce() async {
    if (_verifiedOnOpen || !mounted) return;
    _verifiedOnOpen = true;
    await _verifyAccess();
  }

  Future<void> _verifyAccess() async {
    if (!mounted) return;
    await SubscriptionGuard.ensureActive(context);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
