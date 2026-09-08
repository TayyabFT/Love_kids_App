import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';

/// Auth + subscription gate business logic (formerly in [AuthWrapper]).
class AuthFlowProvider extends ChangeNotifier {
  static const String _logTag = 'SUB_NAV';

  AuthFlowProvider({
    AuthService? authService,
    SubscriptionService? subscriptionService,
  })  : _authService = authService ?? AuthService(),
        _subscriptionService = subscriptionService ?? SubscriptionService();

  final AuthService _authService;
  final SubscriptionService _subscriptionService;

  StreamSubscription<User?>? _authSubscription;
  User? _user;
  bool? _hasActiveSubscription;
  bool _isAuthLoading = true;
  bool _isSubscriptionLoading = false;
  bool _isGoogleUser = false;
  String? _subscriptionUserId;
  Future<bool>? _subscriptionFuture;
  int _subscriptionCheckSeq = 0;

  User? get user => _user;
  bool? get hasActiveSubscription => _hasActiveSubscription;
  bool get isAuthLoading => _isAuthLoading;
  bool get isSubscriptionLoading => _isSubscriptionLoading;
  bool get isGoogleUser => _isGoogleUser;

  bool get isAuthenticated => _user != null;

  void initialize() {
    _authSubscription?.cancel();
    _authSubscription = _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> loadGoogleUserFlag() async {
    _isGoogleUser = await _authService.isGoogleUser();
    _notify('loadGoogleUserFlag');
  }

  Future<void> refreshSubscription() async {
    if (_user == null) return;
    _subscriptionCheckSeq++;
    _subscriptionFuture = null;
    _subscriptionUserId = null;
    await _checkSubscription(_user!, showLoading: false);
  }

  /// Validates subscription (including auto-expiration) and updates access state.
  /// Callable from anywhere via Provider. Returns true when premium is active.
  Future<bool> checkSubscriptionStatus() async {
    print('[$_logTag] AuthFlowProvider.checkSubscriptionStatus() START hasActive=$_hasActiveSubscription');
    if (_user == null) {
      _hasActiveSubscription = false;
      _notify('checkSubscriptionStatus-no-user');
      return false;
    }
    await refreshSubscription();
    final result = _hasActiveSubscription ?? false;
    print('[$_logTag] AuthFlowProvider.checkSubscriptionStatus() END → $result');
    return result;
  }

  void _notify(String reason) {
    print('[$_logTag] AuthFlowProvider.notifyListeners() reason=$reason hasActive=$_hasActiveSubscription');
    notifyListeners();
  }

  Future<void> signOut() => _authService.signOut();

  Future<void> _onAuthStateChanged(User? user) async {
    _subscriptionCheckSeq++;
    _user = user;
    _hasActiveSubscription = null;
    _subscriptionFuture = null;
    _subscriptionUserId = null;

    if (user == null) {
      _isAuthLoading = false;
      _isSubscriptionLoading = false;
      _hasActiveSubscription = false;
      _notify('auth-signed-out');
      return;
    }

    _isAuthLoading = false;
    _isSubscriptionLoading = true;
    _notify('auth-signed-in-pending');
    await _checkSubscription(user, showLoading: false);
    await loadGoogleUserFlag();
  }

  Future<void> _checkSubscription(User user, {required bool showLoading}) async {
    final checkSeq = _subscriptionCheckSeq;
    print(
      '[$_logTag] AuthFlowProvider._checkSubscription() uid=${user.uid} '
      'showLoading=$showLoading seq=$checkSeq',
    );
    if (showLoading) {
      _isSubscriptionLoading = true;
      _notify('checkSubscription-start');
    }

    try {
      if (_subscriptionUserId == user.uid && _subscriptionFuture != null) {
        print('[$_logTag] AuthFlowProvider._checkSubscription() using cached future');
        _hasActiveSubscription = await _subscriptionFuture!;
      } else {
        _subscriptionUserId = user.uid;
        _subscriptionFuture = _subscriptionService.checkSubscriptionStatus();
        _hasActiveSubscription = await _subscriptionFuture!;
      }
      print('[$_logTag] AuthFlowProvider._checkSubscription() result=$_hasActiveSubscription');
      if (_hasActiveSubscription == false) {
        print('[$_logTag] Subscription expired — hasActiveSubscription set to false');
      }
    } catch (e) {
      print('[$_logTag] AuthFlowProvider._checkSubscription() error=$e');
      _hasActiveSubscription = false;
    } finally {
      final isCurrentCheck =
          checkSeq == _subscriptionCheckSeq && _user?.uid == user.uid;
      if (!isCurrentCheck) {
        print(
          '[$_logTag] AuthFlowProvider._checkSubscription() stale result ignored '
          '(uid=${user.uid}, seq=$checkSeq current=$_subscriptionCheckSeq)',
        );
      } else {
        _isSubscriptionLoading = false;
        _notify(showLoading ? 'checkSubscription-end' : 'checkSubscription-silent');
      }
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
