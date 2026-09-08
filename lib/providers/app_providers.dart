import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_flow_provider.dart';
import 'landing_flow_provider.dart';
import 'navigation_provider.dart';
import 'subscription_provider.dart';

class AppProviders {
  static List<ChangeNotifierProvider> get providers => [
        ChangeNotifierProvider<NavigationProvider>(
          create: (_) => NavigationProvider(),
        ),
        ChangeNotifierProvider<AuthFlowProvider>(
          create: (_) {
            final provider = AuthFlowProvider();
            provider.initialize();
            return provider;
          },
        ),
        ChangeNotifierProvider<LandingFlowProvider>(
          create: (_) => LandingFlowProvider(),
        ),
        ChangeNotifierProvider<SubscriptionProvider>(
          create: (_) => SubscriptionProvider(),
        ),
      ];

  static Widget wrap(Widget child) {
    return MultiProvider(
      providers: providers,
      child: child,
    );
  }
}
