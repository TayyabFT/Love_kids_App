import 'package:flutter/material.dart';
import '../navigation/app_route.dart';
import '../navigation/route_generator.dart';
import '../widgets/auth_wrapper.dart';
import '../widgets/subscription_lifecycle_observer.dart';

/// Central navigation stack for the app. Views call this instead of [Navigator] directly.
class NavigationProvider extends ChangeNotifier {
  static const String logTag = 'SUB_NAV';

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final List<String> _stack = [];
  bool _redirectInProgress = false;

  /// False when [pushAndRemoveUntil] replaced [AuthWrapper] (e.g. direct Home push).
  bool _rootIsAuthWrapper = true;

  List<String> get stack => List.unmodifiable(_stack);

  NavigatorState? get _navigator => navigatorKey.currentState;

  Future<T?>? push<T>(AppRoute route, {Object? arguments}) {
    _stack.add(route.path);
    notifyListeners();
    // Use MaterialPageRoute<T> directly — pushNamed<T> fails when onGenerateRoute
    // returns MaterialPageRoute<dynamic> (e.g. push<bool> for subscription cancel).
    return _navigator?.push<T>(
      MaterialPageRoute<T>(
        settings: RouteSettings(name: route.path, arguments: arguments),
        builder: (_) => RouteGenerator.pageFor(route),
      ),
    );
  }

  /// Push a screen not yet registered as a named route (legacy screens).
  Future<T?>? pushPage<T>(Widget page) {
    _stack.add(page.runtimeType.toString());
    notifyListeners();
    return _navigator?.push<T>(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  void pop<T>([T? result]) {
    final nav = _navigator;
    if (nav == null || !nav.canPop()) {
      print('[$logTag] pop skipped — nothing to pop (stack=$_stack)');
      return;
    }
    if (_stack.isNotEmpty) _stack.removeLast();
    nav.pop<T>(result);
    notifyListeners();
  }

  void pushReplacement(AppRoute route, {Object? arguments}) {
    if (_stack.isNotEmpty) _stack.removeLast();
    _stack.add(route.path);
    notifyListeners();
    _navigator?.pushReplacement(
      MaterialPageRoute(
        settings: RouteSettings(name: route.path, arguments: arguments),
        builder: (_) => RouteGenerator.pageFor(route),
      ),
    );
  }

  void pushAndRemoveUntil(AppRoute route, {Object? arguments}) {
    print(
      '[$logTag] pushAndRemoveUntil(${route.path}) — '
      'removes AuthWrapper from stack; avoid for post-purchase navigation',
    );
    _rootIsAuthWrapper = false;
    _stack
      ..clear()
      ..add(route.path);
    notifyListeners();
    _navigator?.pushAndRemoveUntil(
      MaterialPageRoute(
        settings: RouteSettings(name: route.path, arguments: arguments),
        builder: (_) => RouteGenerator.pageFor(route),
      ),
      (_) => false,
    );
  }

  void popUntilRoot() {
    final nav = _navigator;
    if (nav == null) {
      print('[$logTag] popUntilRoot skipped — navigator not ready');
      return;
    }

    if (nav.canPop()) {
      nav.popUntil((route) => route.isFirst);
      _stack.clear();
      print('[$logTag] popUntilRoot — stack cleared, AuthWrapper revealed');
    }

    notifyListeners();
  }

  /// Clears pushed routes and ensures [AuthWrapper] shows the choose-plan screen.
  void redirectToChoosePlan({required String reason}) {
    if (_redirectInProgress) {
      print('[$logTag] redirect skipped — already in progress (reason=$reason)');
      return;
    }

    final nav = _navigator;
    if (nav == null) {
      print('[$logTag] redirect skipped — navigator not ready (reason=$reason)');
      return;
    }

    _redirectInProgress = true;
    final couldPopBefore = nav.canPop();
    print(
      '[$logTag] Subscription expired (reason=$reason, '
      'canPopBefore=$couldPopBefore, rootIsAuthWrapper=$_rootIsAuthWrapper, stack=$_stack)',
    );

    _stack.clear();

    if (couldPopBefore) {
      nav.popUntil((route) => route.isFirst);
      print('[$logTag] Navigation stack cleared — canPopAfter=${nav.canPop()}');
      print('[$logTag] Landing page opened — AuthWrapper revealed underneath');
    } else if (!_rootIsAuthWrapper) {
      nav.pushAndRemoveUntil(
        MaterialPageRoute(
          settings: const RouteSettings(name: '/'),
          builder: (_) => const SubscriptionLifecycleObserver(
            child: AuthWrapper(),
          ),
        ),
        (_) => false,
      );
      _rootIsAuthWrapper = true;
      print('[$logTag] Navigation stack cleared — root reset to AuthWrapper');
      print('[$logTag] Landing page opened — choose plan flow');
    } else {
      print(
        '[$logTag] At AuthWrapper root — LandingPage shown via notifyListeners rebuild',
      );
    }

    notifyListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirectInProgress = false;
    });
  }

  bool get canPop => _navigator?.canPop() ?? false;
}
