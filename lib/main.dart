import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'navigation/route_generator.dart';
import 'providers/app_providers.dart';
import 'providers/navigation_provider.dart';
import 'services/stripe_service.dart';
import 'services/task_service.dart';
import 'theme/app_theme.dart';
import 'widgets/auth_wrapper.dart';
import 'widgets/subscription_lifecycle_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp();
  StripeService.init();
  await TaskService.ensureNotificationsInitialized();
  runApp(AppProviders.wrap(const SelfLoveKidsApp()));
}

class SelfLoveKidsApp extends StatelessWidget {
  const SelfLoveKidsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final navigation = context.watch<NavigationProvider>();

    return MaterialApp(
      title: 'SAY IT NOW SELF-LOVE KIDS APP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorKey: navigation.navigatorKey,
      home: const SubscriptionLifecycleObserver(
        child: AuthWrapper(),
      ),
      onGenerateRoute: RouteGenerator.onGenerateRoute,
    );
  }
}
