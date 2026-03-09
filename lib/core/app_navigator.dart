import 'package:flutter/material.dart';

class AppNavigator {
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  static BuildContext get context => key.currentContext!;

  static Future<T?> pushNamed<T>(String routeName, {Object? arguments}) {
    return key.currentState!.pushNamed<T>(routeName, arguments: arguments);
  }

  static Future<T?> pushReplacementNamed<T, TO>(String routeName,
      {TO? result, Object? arguments}) {
    return key.currentState!.pushReplacementNamed<T, TO>(routeName,
        result: result, arguments: arguments);
  }

  static Future<T?> pushNamedAndRemoveUntil<T>(
      String routeName, bool Function(Route<dynamic>) predicate,
      {Object? arguments}) {
    return key.currentState!
        .pushNamedAndRemoveUntil<T>(routeName, predicate, arguments: arguments);
  }

  static void pop<T>([T? result]) {
    return key.currentState!.pop<T>(result);
  }
}
