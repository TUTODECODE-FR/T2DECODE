import 'package:flutter/material.dart';
import '../providers/shell_provider.dart';
import 'package:provider/provider.dart';

class AppNavigator {
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
  
  static NavigatorState? get state => key.currentState;
  static BuildContext? get context => key.currentContext;

  static final observer = AppRouteObserver();
  
  static Future<T?>? pushNamed<T extends Object?>(String routeName, {Object? arguments}) {
    return state?.pushNamed<T>(routeName, arguments: arguments);
  }

  static Future<T?>? pushReplacementNamed<T extends Object?, TO extends Object?>(String routeName, {TO? result, Object? arguments}) {
    return state?.pushReplacementNamed<T, TO>(routeName, result: result, arguments: arguments);
  }

  static void pop<T extends Object?>([T? result]) {
    state?.pop<T>(result);
  }
}

class AppRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _updateShell(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) _updateShell(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _updateShell(newRoute);
  }

  void _updateShell(Route<dynamic> route) {
    final name = route.settings.name;
    if (name != null) {
      final context = AppNavigator.context;
      if (context != null) {
        // Use post frame callback to avoid issues with build/layout phase
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            Provider.of<ShellProvider>(context, listen: false).setActiveRoute(name);
          } catch (e) {
            debugPrint('ShellProvider update failed: $e');
          }
        });
      }
    }
  }
}
