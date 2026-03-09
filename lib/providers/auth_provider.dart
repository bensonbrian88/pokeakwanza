import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stynext/core/token_service.dart';
import 'package:stynext/core/api/api_service.dart';
import 'package:stynext/services/fcm_service.dart';
import '../core/constants/api_constants.dart';
import 'package:stynext/core/auth/auth_service.dart';
import 'package:stynext/models/phone_code.dart';
import 'package:stynext/models/user_model.dart';
import 'package:stynext/core/navigation_service.dart';
import 'package:stynext/config/app_config.dart';
import 'package:stynext/core/di/service_locator.dart';
import 'package:stynext/domain/usecases/usecases.dart';

class AuthState {
  final bool isLoading;
  final List<PhoneCode> phoneCodes;
  final String? token;
  final Map<String, dynamic>? user;
  final bool isGuest;
  final bool seenOnboarding;
  const AuthState({
    this.isLoading = false,
    this.phoneCodes = const [],
    this.token,
    this.user,
    this.isGuest = false,
    this.seenOnboarding = false,
  });
  bool get isAuthenticated => token != null;
  AuthState copyWith({
    bool? isLoading,
    List<PhoneCode>? phoneCodes,
    String? token,
    Map<String, dynamic>? user,
    bool? isGuest,
    bool? seenOnboarding,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      phoneCodes: phoneCodes ?? this.phoneCodes,
      token: token,
      user: user,
      isGuest: isGuest ?? this.isGuest,
      seenOnboarding: seenOnboarding ?? this.seenOnboarding,
    );
  }
}

class AuthProvider extends StateNotifier<AuthState> {
  SharedPreferences? _prefs;
  final _api = ApiService.I;
  final _auth = AuthService();
  final _tokens = TokenService();

  AuthProvider() : super(const AuthState());

  void _setLoading(bool val) {
    state = state.copyWith(isLoading: val);
  }

  String? _extractToken(Map<String, dynamic> res) {
    final dynamic token = res['token'] ??
        res['access_token'] ??
        res['api_token'] ??
        res['bearer_token'] ??
        (res['data'] is Map
            ? (res['data']['token'] ??
                res['data']['access_token'] ??
                res['data']['api_token'] ??
                res['data']['bearer_token'])
            : null);
    if (token is String && token.isNotEmpty) return token;
    return null;
  }

  Map<String, dynamic>? _extractUser(Map<String, dynamic> res) {
    final dynamic user =
        res['user'] ?? (res['data'] is Map ? res['data']['user'] : null);
    return user is Map<String, dynamic> ? user : null;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final token = await _tokens.getToken();
    final isGuest = _prefs?.getBool('is_guest') ?? false;
    final seenOnboarding = _prefs?.getBool('seenOnboarding') ?? false;
    final userData = _prefs?.getString('user_data');
    if (userData != null) {
      final u = jsonDecode(userData);
      state = state.copyWith(user: u);
    }
    if (token != null) {
      _api.setBearerToken(token);
    }
    state = state.copyWith(
      token: token,
      isGuest: isGuest,
      seenOnboarding: seenOnboarding,
    );
    // when API service signals unauthorized we clear user data and send
    // the user back to login screen via global navigator key.
    _api.onUnauthorized = () {
      final guest = state.isGuest || (_prefs?.getBool('is_guest') ?? false);
      if (guest) {
        return;
      }
      state = state.copyWith(token: null, user: null);
      _tokens.clearToken();
      _api.setBearerToken(null);
      navigatorKey.currentState
          ?.pushNamedAndRemoveUntil('/login', (_) => false);
    };
  }

  Future<void> initialize() => init();

  Future<void> fetchPhoneCodes() async {
    try {
      final res = await _api.getPhoneCodes();
      final list = res.map((e) => PhoneCode.fromJson(e)).toList();
      state = state.copyWith(phoneCodes: list);
    } catch (e) {
      // Silent fail - phone codes are optional
    }
  }

  /// Fetch authenticated user from backend
  /// Returns UserModel with fresh data from the server
  /// Throws exception if unauthorized (401) or network error
  Future<UserModel> fetchUser() async {
    _setLoading(true);
    try {
      if (state.token == null) {
        throw Exception('No authentication token found. Please log in.');
      }

      final userResult = await getIt<FetchUserUseCase>().call();
      final data = userResult.getOrNull();
      final user = data is UserModel
          ? data
          : data is Map<String, dynamic>
              ? UserModel.fromJson(data)
              : await _api.getUser();

      // Update cached user data
      final json = user.toJson();
      state = state.copyWith(user: json);
      if (_prefs != null) {
        await _prefs!.setString('user_data', jsonEncode(json));
      }

      return user;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Clear token and user data
        state = state.copyWith(token: null, user: null);
        await _tokens.clearToken();
        await _prefs?.remove('auth_token');
        await _prefs?.remove('user_data');
        _api.setBearerToken(null);
        throw Exception('Your session has expired. Please log in again.');
      }
      rethrow;
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Update profile information (name, phone, optional photo). Returns updated user.
  Future<UserModel?> updateProfile({
    String? name,
    String? phone,
    File? profilePhoto,
  }) async {
    _setLoading(true);
    try {
      final form = FormData();
      if (name != null) form.fields.add(MapEntry('name', name));
      if (phone != null) form.fields.add(MapEntry('phone', phone));
      if (profilePhoto != null) {
        form.files.add(MapEntry(
          'profile_photo',
          await MultipartFile.fromFile(profilePhoto.path),
        ));
      }
      final res = await _api.postMultipart(ApiConstants.updateProfile, form);
      final json = res.data is Map ? (res.data['data'] ?? res.data) : res.data;
      if (json is Map<String, dynamic>) {
        final user = UserModel.fromJson(json);
        state = state.copyWith(user: user.toJson());
        if (_prefs != null) {
          await _prefs!.setString('user_data', jsonEncode(state.user));
        }
        return user;
      }
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
    return null;
  }

  Future<void> continueAsGuest() async {
    state = state.copyWith(isGuest: true, token: null, user: null);
    if (_prefs != null) {
      await _prefs!.setBool('is_guest', true);
      await _prefs!.remove('auth_token');
      await _prefs!.remove('user_data');
    }
    _tokens.clearToken();
    _api.setBearerToken(null);
  }

  Future<Map<String, dynamic>> login(String login, String password) async {
    _setLoading(true);
    try {
      final result =
          await getIt<LoginUseCase>().call(email: login, password: password);
      final res = result.getOrNull() ?? {};

      if (res['next'] == 'otp_verification' ||
          res['data']?['next'] == 'otp_verification') {
        return res;
      }

      final dynamic userIdRaw = res['user_id'] ?? res['data']?['user_id'];
      final hasToken = _extractToken(res) != null;
      if (userIdRaw != null && !hasToken) {
        return {
          'next': 'otp_verification',
          'user_id': userIdRaw,
          ...res,
        };
      }

      final token = _extractToken(res);
      if (token != null) {
        await _saveAuth(token, _extractUser(res));
        try {
          await fetchUser();
        } catch (_) {}
      }
      return res;
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('Account not verified');
      }
      if (e.response != null) {
        debugPrint('STATUS: ${e.response!.statusCode}');
        debugPrint('ERROR: ${e.response!.data}');
        final msg = e.response!.data is Map
            ? e.response!.data['message']?.toString()
            : null;
        if (msg != null) throw Exception(msg);
      } else {
        debugPrint('NETWORK ERROR');
        throw Exception('Network error');
      }
    } finally {
      _setLoading(false);
    }
    return {};
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> payload) async {
    _setLoading(true);
    try {
      final resResult = await getIt<RegisterUseCase>().call(payload);
      final res = resResult.getOrNull() ?? {};

      debugPrint('✅ Registration response received');

      // Check if OTP verification is required
      final userId = res['user_id'] ?? res['data']?['user_id'];
      if (userId != null) {
        if (EnvironmentConfig.disableOtp) {
          final userData = res['user'] ?? res['data']?['user'];
          if (userData is Map<String, dynamic>) {
            state = state.copyWith(user: userData, isGuest: false);
            await _prefs?.setString('user_data', jsonEncode(userData));
          }
          final loginVal =
              payload['email'] ?? payload['phone'] ?? payload['login'];
          final passVal = payload['password'];
          if (loginVal is String &&
              passVal is String &&
              loginVal.isNotEmpty &&
              passVal.isNotEmpty) {
            try {
              final loginRes = await _auth.login(loginVal, passVal);
              final t = loginRes['token'] ??
                  loginRes['access_token'] ??
                  loginRes['data']?['token'];
              if (t != null) {
                await _saveAuth(
                    t, loginRes['user'] ?? loginRes['data']?['user']);
                try {
                  await fetchUser();
                } catch (_) {}
                navigatorKey.currentState
                    ?.pushNamedAndRemoveUntil('/home', (_) => false);
              }
            } catch (_) {}
          }
          final result = Map<String, dynamic>.from(res);
          result.remove('next');
          result.remove('user_id');
          return result;
        } else {
          return {'next': 'otp_verification', 'user_id': userId, ...res};
        }
      }

      // Check if token is provided (registration + login in one step)
      final token = _extractToken(res);
      if (token != null) {
        debugPrint('✅ Token received, user is logged in');
        await _saveAuth(token, _extractUser(res));
        try {
          await fetchUser();
        } catch (_) {}
        navigatorKey.currentState
            ?.pushNamedAndRemoveUntil('/home', (_) => false);
      }

      return res;
    } on DioException catch (e) {
      debugPrint('❌ Registration failed with DioException');
      debugPrint('   Type: ${e.type}');
      debugPrint('   Status: ${e.response?.statusCode}');

      // Handle timeout
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception(
            'Server not responding. Please check your internet connection and try again.');
      }

      // Handle no internet
      if (e.error is SocketException) {
        throw Exception(
            'No internet connection. Please check your network and try again.');
      }

      // Handle validation errors (422)
      if (e.response?.statusCode == 422) {
        final data = e.response?.data;
        if (data is Map) {
          final errors = data['errors'];
          if (errors is Map) {
            final errorList = <String>[];
            errors.forEach((field, messages) {
              if (messages is List && messages.isNotEmpty) {
                final msg = messages.first.toString();
                if (msg.contains('has already been taken')) {
                  errorList.add('User already registered');
                } else {
                  errorList.add(msg);
                }
              }
            });
            if (errorList.isNotEmpty) {
              throw Exception(errorList.join(', '));
            }
          }

          final msg = data['message'];
          if (msg is String && msg.isNotEmpty) {
            if (msg.contains('has already been taken')) {
              throw Exception('User already registered');
            }
            throw Exception(msg);
          }
        }
        throw Exception('Validation error. Please check your input.');
      }

      // Handle server errors (500+)
      if ((e.response?.statusCode ?? 0) >= 500) {
        final data = e.response?.data;
        if (data is Map) {
          final msg = data['message'];
          if (msg is String && msg.isNotEmpty) {
            throw Exception(msg);
          }
        }
        throw Exception('Server error. Please try again later.');
      }

      // Handle other HTTP errors
      if (e.response != null) {
        debugPrint('   Response: ${e.response!.data}');
        final msg = e.response!.data is Map
            ? e.response!.data['message']?.toString()
            : null;
        if (msg != null && msg.isNotEmpty) {
          throw Exception(msg);
        }
      }

      throw Exception('Registration failed. Please try again.');
    } catch (e) {
      debugPrint('❌ Registration failed: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('An unexpected error occurred. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> verifyOtp(int userId, String otpCode) async {
    _setLoading(true);
    try {
      final res = await _auth.verifyOtp(userId, otpCode);
      final token = _extractToken(res);
      if (token != null) {
        await _saveAuth(token, _extractUser(res));
      }
      return res;
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        throw Exception('Invalid code');
      }
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized');
      }
      if (e.response?.statusCode == 403) {
        throw Exception('OTP expired');
      }
      final msg = e.response?.data is Map
          ? e.response?.data['message']?.toString()
          : null;
      if (msg != null) throw Exception(msg);
      throw Exception('Network or server error');
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> verifyOtpEmail(
      String email, String otpCode) async {
    _setLoading(true);
    try {
      final res = await _api.verifyOtpEmail(email, otpCode);
      final token = _extractToken(res);
      if (token != null) {
        await _saveAuth(token, _extractUser(res));
      }
      return res;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> resendOtp(int userId) async {
    _setLoading(true);
    try {
      return await _auth.resendOtp(userId);
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? e.response?.data['message']?.toString()
          : null;
      if (msg != null) throw Exception(msg);
      throw Exception('Network or server error');
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> resendOtpEmail(String email) async {
    _setLoading(true);
    try {
      return await _api.resendOtpEmail(email);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _saveAuth(String token, Map<String, dynamic>? userData) async {
    state = state.copyWith(token: token, user: userData, isGuest: false);
    _api.setBearerToken(token);
    await _prefs?.remove('is_guest');
    await _tokens.saveToken(token);
    await _prefs?.setString('auth_token', token);
    if (userData != null) {
      await _prefs?.setString('user_data', jsonEncode(userData));
    }

    // Register FCM token with backend after successful authentication
    try {
      await FCMService().registerFCMToken();
    } catch (e) {
      debugPrint('⚠️ FCM token registration error (non-critical): $e');
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      // Unregister FCM token from backend
      try {
        await FCMService().unregisterToken();
      } catch (e) {
        debugPrint('⚠️ FCM token unregistration error (non-critical): $e');
      }

      final _ = await getIt<LogoutUseCase>().call();
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      state = state.copyWith(token: null, user: null);
      await _tokens.clearToken();
      await _prefs?.remove('auth_token');
      await _prefs?.remove('user_data');
      _api.setBearerToken(null);
      _setLoading(false);
    }
  }

  Future<void> completeOnboarding() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setBool('seenOnboarding', true);
    state = state.copyWith(seenOnboarding: true);
  }
}

final authProvider = StateNotifierProvider<AuthProvider, AuthState>(
    (ref) => AuthProvider()..init());
