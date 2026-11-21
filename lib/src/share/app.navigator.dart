import 'dart:developer' as developer;
import 'package:flutter/cupertino.dart';

import 'app_routes.dart';

class AppNavigator {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static Future<T?> pushNamed<T>(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!
        .pushNamed<T>(routeName, arguments: arguments);
  }

  static void pop<T>([T? result]) {
    return navigatorKey.currentState!.pop(result);
  }

  static void popUntil(String routeName) {
    navigatorKey.currentState!.popUntil((route) {
      developer.log('ruta actual: ${route.settings.name}', name: 'AppNavigator');
      return route.settings.name == routeName;
    });
  }

  static void popUntilFirst() {
    navigatorKey.currentState!.popUntil((route) => route.isFirst);
  }


  static Future<T?> pushNamedAndRemoveUntil<T>(
    String routeName, {
    Object? arguments,
    bool Function(Route<dynamic>)?
        predicate, // <--- 1. Agrega este parámetro opcional
  }) {
    return navigatorKey.currentState!.pushNamedAndRemoveUntil<T>(
      routeName,
      // 2. Si no pasas nada, usa (route) => false para borrar TODO el historial
      predicate ?? (route) => false,
      arguments: arguments,
    );
  }

  static Future<T?> pushReplacementNamed<T>(String routeName,
      {Object? arguments}) {
    return navigatorKey.currentState!
        .pushReplacementNamed<T, T>(routeName, arguments: arguments);
  }

  static void goToLogin() {
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    nav.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }
}
