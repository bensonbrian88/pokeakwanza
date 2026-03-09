import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stynext/models/user_model.dart';
import 'package:stynext/core/auth/auth_service.dart';
import 'package:stynext/core/token_service.dart';
import 'package:stynext/core/api/api_service.dart';

class AuthController extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthService _auth;
  final TokenService _tokens;
  final ApiService _api;

  AuthController(this._auth, this._tokens, this._api)
      : super(const AsyncValue.data(null));

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final res = await _auth.login(email, password);
      final token =
          res['token'] ?? res['access_token'] ?? res['data']?['token'];
      if (token is String && token.isNotEmpty) {
        await _tokens.saveToken(token);
        _api.setBearerToken(token);
      }
      final userJson = res['user'] ?? res['data']?['user'];
      if (userJson is Map<String, dynamic>) {
        final user = UserModel.fromJson(userJson);
        state = AsyncValue.data(user);
        return;
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> register(
      String name, String email, String phone, String password) async {
    state = const AsyncLoading();
    try {
      final payload = {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
      };
      final res = await _auth.register(payload);
      final token =
          res['token'] ?? res['access_token'] ?? res['data']?['token'];
      if (token is String && token.isNotEmpty) {
        await _tokens.saveToken(token);
        _api.setBearerToken(token);
      }
      final userJson = res['user'] ?? res['data']?['user'];
      if (userJson is Map<String, dynamic>) {
        final user = UserModel.fromJson(userJson);
        state = AsyncValue.data(user);
        return;
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadUser() async {
    try {
      final token = await _tokens.getToken();
      if (token == null || token.isEmpty) {
        state = const AsyncValue.data(null);
        return;
      }
      _api.setBearerToken(token);
      final user = await _api.getUser();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    try {
      await _tokens.clearToken();
      _api.setBearerToken(null);
    } finally {
      state = const AsyncValue.data(null);
    }
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<UserModel?>>((ref) {
  return AuthController(AuthService(), TokenService(), ApiService.I);
});
