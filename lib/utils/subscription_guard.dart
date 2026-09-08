import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../navigation/app_route.dart';
import '../providers/auth_flow_provider.dart';
import '../providers/navigation_provider.dart';

/// Routes that require an active subscription before navigation or use.
const Set<AppRoute> subscriptionProtectedRoutes = {
  // Home is gated by AuthWrapper — do not wrap/re-check here (avoids init loops).
  AppRoute.cart,
  AppRoute.trackOrder,
  AppRoute.readBooks,
  AppRoute.affirmation,
  AppRoute.game,
  AppRoute.tasks,
  AppRoute.product,
};

/// Central subscription access checks and redirect to the choose-plan screen.
class SubscriptionGuard {
  static const String logTag = 'SUB_NAV';

  /// Validates subscription server-side and updates [AuthFlowProvider].
  /// Returns `false` and redirects to choose plan when access is not active.
  static Future<bool> ensureActive(BuildContext context) async {
    final authFlow = context.read<AuthFlowProvider>();
    if (!authFlow.isAuthenticated) return false;

    final isActive = await authFlow.checkSubscriptionStatus();
    if (!isActive && context.mounted) {
      redirectToChoosePlan(context, reason: 'ensureActive-check-failed');
    }
    return isActive;
  }

  /// Clears the navigation stack and ensures [AuthWrapper] shows [LandingPage].
  static void redirectToChoosePlan(
    BuildContext context, {
    required String reason,
  }) {
    context.read<NavigationProvider>().redirectToChoosePlan(reason: reason);
  }

  static bool isProtectedRoute(AppRoute route) =>
      subscriptionProtectedRoutes.contains(route);

  /// Guarded navigation — blocks push when subscription is expired.
  static Future<T?>? pushIfActive<T>(
    BuildContext context,
    AppRoute route, {
    Object? arguments,
  }) async {
    if (isProtectedRoute(route)) {
      if (!await ensureActive(context)) return null;
    }
    if (!context.mounted) return null;
    return context.read<NavigationProvider>().push<T>(
      route,
      arguments: arguments,
    );
  }
}
