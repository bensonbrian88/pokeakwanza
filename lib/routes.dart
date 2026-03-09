import 'package:flutter/material.dart';
import 'package:stynext/features/auth/login_screen.dart';
import 'package:stynext/features/auth/register_screen.dart';
import 'package:stynext/features/auth/otp_screen.dart';
import 'package:stynext/features/auth/forgot_password_screen.dart';
import 'package:stynext/features/onboarding/onboarding_screen.dart';
import 'package:stynext/features/splash/splash_screen.dart';
import 'package:stynext/features/home/main_screen.dart';
import 'package:stynext/features/home/home_screen.dart';
import 'package:stynext/features/auth/auth_landing_screen.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
      case 'Splash':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case 'OnBoarding':
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case 'SignInOptions':
        return MaterialPageRoute(builder: (_) => const AuthLandingScreen());
      case 'Login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case 'Register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case 'OtpScreen':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => OtpScreen(userId: args?['user_id']),
        );
      case 'ForgotPassword':
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case 'MainScreen':
        return MaterialPageRoute(builder: (_) => const MainScreen());
      case 'Home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
