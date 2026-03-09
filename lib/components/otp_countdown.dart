import 'dart:async';
import 'package:flutter/material.dart';

class OtpCountdown extends StatefulWidget {
  final Future<void> Function() onResend;

  const OtpCountdown({Key? key, required this.onResend}) : super(key: key);

  @override
  State<OtpCountdown> createState() => _OtpCountdownState();
}

class _OtpCountdownState extends State<OtpCountdown> {
  static const int _initialSeconds = 60;
  int secondsRemaining = _initialSeconds;
  Timer? _timer;
  bool canResend = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() {
      secondsRemaining = _initialSeconds;
      canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining > 1) {
        setState(() {
          secondsRemaining--;
        });
      } else {
        timer.cancel();
        setState(() {
          secondsRemaining = 0;
          canResend = true;
        });
      }
    });
  }

  Future<void> _handleResend() async {
    if (!canResend) return;
    setState(() {
      canResend = false;
    });
    await widget.onResend();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return canResend
        ? TextButton(
            onPressed: _handleResend,
            child: const Text('Resend OTP'),
          )
        : Text('Resend OTP in $secondsRemaining s');
  }
}
