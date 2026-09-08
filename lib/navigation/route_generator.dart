import 'package:flutter/material.dart';
import 'package:sayitnowwithselflovekids/screens/cart_screen.dart';
import 'package:sayitnowwithselflovekids/screens/track_order_screen.dart';
import '../navigation/app_route.dart';
import '../screens/affirmation_screen.dart';
import '../screens/game_screen.dart';
import '../screens/home_page.dart';
import '../screens/landing_page.dart';
import '../screens/login_page.dart';
import '../screens/product_screen.dart';
import '../screens/read_books.dart';
import '../screens/signup_page.dart';
import '../screens/subscription_screen.dart';
import '../screens/task_screen.dart';
import '../utils/subscription_guard.dart';
import '../widgets/subscription_protected_screen.dart';

class RouteGenerator {
  static AppRoute? _routeFromName(String? name) {
    if (name == null) return null;
    for (final route in AppRoute.values) {
      if (route.path == name) return route;
    }
    return null;
  }

  static Widget pageFor(AppRoute route) {
    final page = switch (route) {
      AppRoute.landing => const LandingPage(),
      AppRoute.login => const LoginPage(),
      AppRoute.signup => const SignupPage(),
      AppRoute.home => const HomePage(),
      AppRoute.cart => const CartScreen(),
      AppRoute.trackOrder => const TrackOrderScreen(),
      AppRoute.subscription => const SubscriptionScreen(),
      AppRoute.readBooks => const ReadBooks(),
      AppRoute.affirmation => const AffirmationScreen(),
      AppRoute.game => const GameScreen(),
      AppRoute.tasks => const TaskManagement(),
      AppRoute.product => const ProductScreen(),
    };

    if (SubscriptionGuard.isProtectedRoute(route)) {
      return SubscriptionProtectedScreen(child: page);
    }
    return page;
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final route = _routeFromName(settings.name);
    if (route == null) return null;

    return MaterialPageRoute(
      settings: settings,
      builder: (_) => pageFor(route),
    );
  }
}
