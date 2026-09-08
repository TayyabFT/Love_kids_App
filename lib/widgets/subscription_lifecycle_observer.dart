import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_flow_provider.dart';
import '../utils/subscription_guard.dart';

/// Re-checks subscription on resume / periodically and redirects when inactive.
class SubscriptionLifecycleObserver extends StatefulWidget {
  final Widget child;

  const SubscriptionLifecycleObserver({super.key, required this.child});

  @override
  State<SubscriptionLifecycleObserver> createState() =>
      _SubscriptionLifecycleObserverState();
}

class _SubscriptionLifecycleObserverState extends State<SubscriptionLifecycleObserver>
    with WidgetsBindingObserver {
  static const Duration _validationInterval = Duration(hours: 1);

  Timer? _periodicTimer;
  AuthFlowProvider? _authFlow;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onForeground());
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
    _stopPeriodicTimer();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _onForeground();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _onBackground();
        break;
    }
  }

  void _onAuthFlowChanged() {
    if (!mounted || _authFlow == null) return;
    if (!_authFlow!.isAuthenticated) return;
    if (_authFlow!.isSubscriptionLoading) return;
    if (_authFlow!.hasActiveSubscription == null) return;
    if (_authFlow!.hasActiveSubscription != false) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        SubscriptionGuard.redirectToChoosePlan(
          context,
          reason: 'auth-state-inactive',
        );
      }
    });
  }

  void _onForeground() {
    _validateSubscription(reason: 'app-foreground');
    _startPeriodicTimer();
  }

  void _onBackground() {
    _stopPeriodicTimer();
  }

  void _startPeriodicTimer() {
    _stopPeriodicTimer();

    final authFlow = context.read<AuthFlowProvider>();
    if (!authFlow.isAuthenticated) return;

    _periodicTimer = Timer.periodic(_validationInterval, (_) {
      _validateSubscription(reason: 'periodic-check');
    });
  }

  void _stopPeriodicTimer() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  Future<void> _validateSubscription({required String reason}) async {
    if (!mounted) return;

    final authFlow = context.read<AuthFlowProvider>();
    if (!authFlow.isAuthenticated) {
      _stopPeriodicTimer();
      return;
    }

    final isActive = await authFlow.checkSubscriptionStatus();
    if (!mounted) return;

    if (!isActive) {
      _stopPeriodicTimer();
      SubscriptionGuard.redirectToChoosePlan(
        context,
        reason: 'subscription-expired-$reason',
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
