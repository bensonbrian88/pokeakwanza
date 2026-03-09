import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';
import 'package:stynext/core/theme/app_theme.dart';
import 'package:stynext/core/auth/app_start_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 10));
    if (mounted) {
      // Re-fetch start destination to account for Guest Mode persistence
      final prefs = await SharedPreferences.getInstance();
      final isGuest = prefs.getBool('is_guest') ?? false;
      final token = prefs.getString('auth_token');

      if (isGuest || (token != null && token.isNotEmpty)) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        AppStartRouter.navigateFromSplash(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Center Logo with Bounce Animation
            Bounce(
              duration: const Duration(seconds: 2),
              infinite: true,
              child: Image.asset(
                'assets/images/logo.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.shopping_bag_outlined,
                  size: 120,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 48),
            // Loading indicator at the bottom
            FadeIn(
              duration: const Duration(milliseconds: 1000),
              delay: const Duration(seconds: 2),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
