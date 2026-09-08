import 'package:flutter/foundation.dart';
import '../services/stripe_service.dart';
import '../services/subscription_service.dart';
import 'auth_flow_provider.dart';

/// Subscription details and cancellation logic (UI-agnostic).
class SubscriptionProvider extends ChangeNotifier {
  static const String _logTag = 'SUB_NAV';

  SubscriptionProvider({SubscriptionService? subscriptionService})
      : _subscriptionService = subscriptionService ?? SubscriptionService();

  final SubscriptionService _subscriptionService;

  Map<String, dynamic>? _details;
  bool _serverVerifiedActive = false;
  bool _isLoading = false;
  bool _isCancelling = false;
  String? _errorMessage;

  Map<String, dynamic>? get details => _details;
  bool get isLoading => _isLoading;
  bool get isCancelling => _isCancelling;
  String? get errorMessage => _errorMessage;

  /// Reflects the last server-validated access check (not device clock).
  bool get isActive => _serverVerifiedActive;

  String get statusLabel {
    final status = _details?['status'] as String?;
    if (status == 'expired' || _details?['expiredAt'] != null) {
      return 'Expired';
    }
    if (status == 'cancelled' || _details?['cancelledAt'] != null) {
      return 'Cancelled';
    }
    if (isActive) return 'Active';
    return 'Inactive';
  }

  String planDisplayName(String? planType) {
    if (planType == 'monthly') {
      return StripeService.getMonthlyPlan()['title'] as String;
    }
    if (planType == 'yearly') {
      return StripeService.getYearlyPlan()['title'] as String;
    }
    return planType ?? 'Unknown Plan';
  }

  /// Loads details after validating access through [AuthFlowProvider].
  Future<void> loadDetails(AuthFlowProvider authFlow) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _serverVerifiedActive = await authFlow.checkSubscriptionStatus();
      _details = await _subscriptionService.getSubscriptionDetails();
      print(
        '[$_logTag] SubscriptionProvider.loadDetails() '
        'serverVerifiedActive=$_serverVerifiedActive status=${_details?['status']}',
      );
    } catch (e) {
      _serverVerifiedActive = false;
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Returns `true` when cancellation succeeded.
  Future<bool> cancelSubscription(AuthFlowProvider authFlow) async {
    _isCancelling = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _subscriptionService.cancelSubscription();
      await loadDetails(authFlow);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isCancelling = false;
      notifyListeners();
    }
  }
}
