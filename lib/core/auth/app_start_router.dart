import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppStartRouter {
  static Future<void> navigateFromSplash(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

    if (!onboardingCompleted) {
      Navigator.of(context).pushReplacementNamed('/onboarding');
      return;
    }

    final token = prefs.getString('auth_token');
    final isGuest = prefs.getBool('is_guest') ?? false;

    if ((token != null && token.isNotEmpty) || isGuest) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }
}
