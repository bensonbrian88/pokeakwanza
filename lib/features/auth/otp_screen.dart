import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stynext/providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final dynamic userId;
  const OtpScreen({Key? key, this.userId}) : super(key: key);

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  static const int initialSeconds = 60;
  Timer? _timer;
  int _seconds = initialSeconds;
  bool _canResend = false;
  int? _userIdArg;
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  String? _errorText;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        final uid = args['user_id'];
        if (uid is int) _userIdArg = uid;
        if (uid is String) {
          final p = int.tryParse(uid);
          if (p != null) _userIdArg = p;
        }
      }
      setState(() {});
    });
    startTimer();
  }

  void startTimer() {
    _seconds = initialSeconds;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds > 0) {
        setState(() {
          _seconds--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  void _showError(String message) {
    setState(() {
      _errorText = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> resendOtp() async {
    if (!_canResend) return;
    final authNotifier = ref.read(authProvider.notifier);
    try {
      if (_userIdArg == null) {
        _showError('User ID not provided');
        return;
      }
      await authNotifier.resendOtp(_userIdArg!);
      startTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP resent successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> verifyOtp() async {
    String otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      _showError('Please enter the 6-digit code');
      return;
    }
    final authNotifier = ref.read(authProvider.notifier);
    try {
      if (_userIdArg == null) {
        _showError('User ID not provided');
        return;
      }
      await authNotifier.verifyOtp(_userIdArg!, otp);
      if (mounted && ref.read(authProvider).isAuthenticated) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String get timerText => '00:${_seconds.toString().padLeft(2, '0')}';
  bool get isVerifyEnabled => _seconds > 0;
  bool get isResendEnabled => _seconds == 0;

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Verification Code',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the 6-digit code sent to your phone',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) {
                return Container(
                  width: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: TextField(
                    controller: _otpControllers[i],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    decoration: const InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      if (val.isNotEmpty && i < 5) {
                        FocusScope.of(context).nextFocus();
                      } else if (val.isEmpty && i > 0) {
                        FocusScope.of(context).previousFocus();
                      }
                    },
                  ),
                );
              }),
            ),
            if (_errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _errorText!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            const SizedBox(height: 24),
            Text(
              timerText,
              style: TextStyle(
                fontSize: 24,
                color: _seconds == 0 ? Colors.red : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_seconds == 0)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'OTP expired. Please resend.',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isVerifyEnabled && !isLoading ? verifyOtp : null,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Verify'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: isResendEnabled && !isLoading ? resendOtp : null,
              child: isResendEnabled
                  ? const Text('Resend OTP')
                  : Text('Resend OTP (${_seconds}s)'),
            ),
          ],
        ),
      ),
    );
  }
}
