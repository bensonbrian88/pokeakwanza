import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:stynext/core/theme/app_theme.dart';
import 'package:stynext/providers/auth_provider.dart';
import 'package:stynext/models/phone_code.dart';
import 'otp_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  PhoneCode? _selectedPhoneCode;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).fetchPhoneCodes().then((_) {
        final codes = ref.read(authProvider).phoneCodes;
        if (codes.isNotEmpty) {
          setState(() {
            _selectedPhoneCode = codes.firstWhere(
              (element) => element.code == '+255' || element.code == '255',
              orElse: () => codes.first,
            );
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPhoneCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a phone code')),
      );
      return;
    }

    final rawNumber = _phoneController.text.trim();
    final digits = rawNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final fullPhone = '${_selectedPhoneCode!.code}$digits';

    final payload = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': fullPhone,
      'password': _passwordController.text,
      'password_confirmation': _confirmPasswordController.text,
    };

    final authNotifier = ref.read(authProvider.notifier);
    try {
      final res = await authNotifier.register(payload);
      if (!mounted) return;

      // If registration failed (no success or user_id), show detailed error if present
      if (res['success'] == false) {
        String msg = res['message']?.toString() ?? '';
        if (msg.isEmpty && res['errors'] is Map) {
          final errs = (res['errors'] as Map)
              .entries
              .expand((e) => (e.value is List ? e.value : [e.value]))
              .map((e) => e.toString())
              .where((s) => s.isNotEmpty)
              .join(', ');
          if (errs.isNotEmpty) msg = errs;
        }
        if (msg.isEmpty) msg = 'Registration failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
        return;
      }

      // If server error (statusCode 500), show error and do not navigate
      if (res['statusCode'] == 500) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Server error. Try again.'),
              backgroundColor: Colors.red),
        );
        return;
      }

      // Only navigate to OTP if success and user_id present
      if (res['success'] == true && res['user_id'] != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(userId: res['user_id']),
          ),
        );
        return;
      }

      // If backend returns next: 'otp_verification' (legacy), also navigate
      if (res['next'] == 'otp_verification') {
        final userId = res['user_id'] ?? res['data']?['user_id'];
        if (userId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpScreen(userId: userId),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('User ID missing for OTP verification'),
                backgroundColor: Colors.red),
          );
        }
        return;
      }

      // Never auto-navigate to login after register
      // Remove any pushReplacement to LoginScreen

      // If nothing matches, show message if present
      final fallbackMsg = res['message']?.toString();
      if (fallbackMsg != null && fallbackMsg.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(fallbackMsg), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Registration failed'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg.isNotEmpty ? msg : 'Network error'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInDown(
                duration: const Duration(milliseconds: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unda Akaunti',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Jaza maelezo yako kuanza',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              FadeInUp(
                duration: const Duration(milliseconds: 800),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Full Name'),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            hintText: 'Enter your full name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (val) =>
                              val!.isEmpty ? 'Please enter your name' : null,
                        ),
                        const SizedBox(height: 20),
                        _buildLabel('Email Address'),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'Enter your email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (val) =>
                              val!.isEmpty ? 'Please enter your email' : null,
                        ),
                        const SizedBox(height: 20),
                        _buildLabel('Phone Number'),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 56,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                border: Border.all(color: Colors.grey[200]!),
                                borderRadius: BorderRadius.circular(
                                    AppTheme.borderRadius),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<PhoneCode>(
                                  value: _selectedPhoneCode,
                                  items: ref
                                      .watch(authProvider)
                                      .phoneCodes
                                      .map((code) => DropdownMenuItem(
                                            value: code,
                                            child: Text(code.code),
                                          ))
                                      .toList(),
                                  onChanged: (val) =>
                                      setState(() => _selectedPhoneCode = val),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  hintText: 'Phone number',
                                ),
                                validator: (val) =>
                                    val!.isEmpty ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildLabel('Password'),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Create a password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (val) =>
                              val!.length < 6 ? 'Minimum 6 characters' : null,
                        ),
                        const SizedBox(height: 20),
                        _buildLabel('Confirm Password'),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscurePassword,
                          decoration: const InputDecoration(
                            hintText: 'Confirm your password',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: (val) => val != _passwordController.text
                              ? 'Passwords do not match'
                              : null,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: isLoading ? null : _register,
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Jisajili'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeInUp(
                duration: const Duration(milliseconds: 1000),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Ingia',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
    );
  }
}
