import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stynext/providers/auth_provider.dart';
import 'package:stynext/services/auth_service.dart';
import 'package:stynext/config/app_config.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                "assets/icons/applogo1.png",
                height: 120,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _loginController,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: 'Email or Phone',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final login = _loginController.text.trim();
                          final pass = _passwordController.text;
                          if (login.isEmpty || pass.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Please enter login and password'),
                              ),
                            );
                            return;
                          }
                          try {
                            final res = await ref
                                .read(authProvider.notifier)
                                .login(login, pass);
                            if (!mounted) return;
                            final state = ref.read(authProvider);
                            final next = res['next'];
                            final userId =
                                res['user_id'] ?? res['data']?['user_id'];
                            if (next == 'otp_verification' && userId != null) {
                              Navigator.pushNamed(context, '/otp',
                                  arguments: {'user_id': userId});
                            } else if (state.isAuthenticated) {
                              Navigator.pushReplacementNamed(context, '/home');
                            } else {
                              final msg = res['message']?.toString() ??
                                  'Login failed. Please try again.';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(msg)),
                              );
                            }
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceFirst('Exception: ', ''),
                                ),
                              ),
                            );
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Login'),
                ),
              ),
              const SizedBox(height: 16),
              if (!EnvironmentConfig.disableGoogleSignIn)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 2,
                      shadowColor: Colors.black12,
                    ),
                    icon: Image.asset(
                      "assets/icons/google.png",
                      height: 24,
                    ),
                    label: const Text(
                      "Sign in with Google",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () async {
                      try {
                        await AppAuthService.signInWithGoogle();
                        if (!mounted) return;
                        Navigator.pushReplacementNamed(context, '/home');
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Google sign-in failed: $e')),
                          );
                        }
                      }
                    },
                  ),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('is_guest', true);
                  if (!mounted) return;
                  Navigator.pushReplacementNamed(context, '/home');
                },
                child: const Text(
                  "Continue as Guest",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: const Text("Create Account"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
