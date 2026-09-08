import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/stripe_service.dart';
import '../services/subscription_service.dart';

/// Landing page subscription purchase and user bootstrap logic.
class LandingFlowProvider extends ChangeNotifier {
  LandingFlowProvider({
    AuthService? authService,
    SubscriptionService? subscriptionService,
  })  : _authService = authService ?? AuthService(),
        _subscriptionService = subscriptionService ?? SubscriptionService();

  final AuthService _authService;
  final SubscriptionService _subscriptionService;

  User? _currentUser;
  bool _isGoogleUser = false;
  bool _isProcessingPayment = false;
  bool _isInitializing = false;
  String? _lastPaymentError;

  User? get currentUser => _currentUser ?? _authService.currentUser;
  bool get isGoogleUser => _isGoogleUser;
  bool get isProcessingPayment => _isProcessingPayment;
  bool get isInitializing => _isInitializing;
  String? get lastPaymentError => _lastPaymentError;

  Future<void> initialize() async {
    _isInitializing = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = _authService.currentUser;
    await _checkUserType(notify: false);

    _isInitializing = false;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    _currentUser = _authService.currentUser;
    await _checkUserType();
  }

  Future<void> _checkUserType({bool notify = true}) async {
    _isGoogleUser = await _authService.isGoogleUser();
    if (notify) notifyListeners();
  }

  /// Processes Stripe payment and creates Firestore subscription.
  /// Returns `true` on success.
  Future<bool> purchasePlan(Map<String, dynamic> plan) async {
    final user = currentUser;
    if (user == null) return false;

    _isProcessingPayment = true;
    _lastPaymentError = null;
    notifyListeners();

    try {
      final double price = (plan['price'] as num).toDouble();
      final String planType = plan['planType'] as String;

      final result = await StripeService.processPayment(
        planType: planType,
        amount: price,
      );

      if (result.cancelled) return false;

      if (!result.success) {
        _lastPaymentError = result.message;
        notifyListeners();
        return false;
      }

      await _subscriptionService.createSubscription(
        planType: planType,
        amount: price,
        paymentIntentId: result.paymentIntentId ?? 'unknown',
      );
      return true;
    } catch (e) {
      _lastPaymentError = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isProcessingPayment = false;
      notifyListeners();
    }
  }
}
