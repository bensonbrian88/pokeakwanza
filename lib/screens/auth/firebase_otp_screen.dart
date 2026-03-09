import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stynext/services/auth_service.dart';

class FirebaseOtpScreen extends StatefulWidget {
  final String verificationId;
  const FirebaseOtpScreen({super.key, required this.verificationId});

  @override
  State<FirebaseOtpScreen> createState() => _FirebaseOtpScreenState();
}

class _FirebaseOtpScreenState extends State<FirebaseOtpScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length < 6) return;
    setState(() => _isLoading = true);
    try {
      await AppAuthService.signInWithOTP(
        verificationId: widget.verificationId,
        smsCode: code,
      );
      try {
        await AppAuthService.syncUserToBackend();
      } catch (e) {
        // Best-effort sync; inform the user but don't block navigation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Backend sync failed: $e')),
          );
        }
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_guest', false);
      if (!mounted) return;
      Navigator.popUntil(context, ModalRoute.withName('/login'));
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter SMS Code')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                hintText: '123456',
                border: OutlineInputBorder(),
                labelText: 'OTP Code',
              ),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _verify,
                    child: const Text('Verify'),
                  ),
          ],
        ),
      ),
    );
  }
}
