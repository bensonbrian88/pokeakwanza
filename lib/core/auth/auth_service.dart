import 'package:flutter/foundation.dart';
import 'package:stynext/core/api/api_service.dart';
import 'package:stynext/core/api_config.dart';

class AuthService {
  final ApiService _api = ApiService.I;

  Future<Map<String, dynamic>> register(Map<String, dynamic> payload) async {
    final p = Map<String, dynamic>.from(payload);
    final phone = p['phone'];
    if (phone is String) {
      p['phone'] = _normalizePhone(phone);
    }
    if (!p.containsKey('password_confirmation') && p['password'] is String) {
      p['password_confirmation'] = p['password'];
    }
    try {
      if (ApiConfig.enableDebugLogs) {
        debugPrint('🔐 AuthService.register() called');
        debugPrint('   Fields: ${p.keys.toList()}');
      }

      final res = await _api.register(p);

      if (ApiConfig.enableDebugLogs) {
        debugPrint('✅ Registration result keys: ${res.keys.toList()}');
      }

      return res;
    } catch (e) {
      if (ApiConfig.enableDebugLogs) {
        debugPrint('❌ Registration error: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login(String login, String password) async {
    try {
      if (ApiConfig.enableDebugLogs) {
        debugPrint('🔐 AuthService.login() called with login: $login');
      }

      final res = await _api.login(login, password);
      return res;
    } catch (e) {
      if (ApiConfig.enableDebugLogs) {
        debugPrint('❌ Login error: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyOtp(int userId, String otpCode) async {
    if (ApiConfig.enableDebugLogs) {
      debugPrint('🔐 AuthService.verifyOtp() called for user: $userId');
    }
    // Use ApiService helper that matches backend (otp_code)
    final res = await _api.verifyOtp(userId, otpCode);
    return res;
  }

  Future<Map<String, dynamic>> resendOtp(int userId) async {
    if (ApiConfig.enableDebugLogs) {
      debugPrint('🔐 AuthService.resendOtp() called for user: $userId');
    }
    final res = await _api.resendOtp(userId);
    return res;
  }

  // Removed _extractMap: ApiService already returns parsed Map

  String _normalizePhone(String input) {
    final raw = input.trim();
    var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    // Convert local TZ numbers like 07xx... to +2557xx...
    if (digits.startsWith('0') && digits.length >= 10) {
      digits = '255${digits.substring(1)}';
    }
    // Ensure + prefix for E.164 if starting with 255
    if (digits.startsWith('255')) {
      return '+$digits';
    }
    // If user already entered +<countrycode>..., keep it
    if (raw.startsWith('+') && digits.isNotEmpty) {
      return '+$digits';
    }
    // Fallback: return as entered trimmed
    return raw;
  }
}
