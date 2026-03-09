import 'package:flutter/material.dart';
import 'package:stynext/services/phone_auth_service.dart';
import 'package:stynext/services/auth_service.dart';

class OTPScreen extends StatefulWidget {
  final String verificationId;

  const OTPScreen({super.key, required this.verificationId});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final otpController = TextEditingController();

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Enter OTP")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "Enter 6 digit OTP",
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await PhoneAuthService().verifyOTP(
                  verificationId: widget.verificationId,
                  smsCode: otpController.text,
                );
                try {
                  await AppAuthService.syncUserToBackend();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Backend sync failed: $e')),
                    );
                  }
                }
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, "/home");
              },
              child: const Text("Verify"),
            )
          ],
        ),
      ),
    );
  }
}
