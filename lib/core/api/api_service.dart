import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:stynext/config/api_config.dart';
import 'package:stynext/core/api/api_constants.dart';
import 'package:stynext/models/user_model.dart';
import 'package:dio/dio.dart' as dio;

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  static final ApiService I = ApiService._();
  ApiService._();
  static const int _defaultPerPage = 100;
  static const int _defaultCategoryProductsLimit = 100;

  String? _token;
  Function()? onUnauthorized;

  void setBearerToken(String? token) {
    _token = token;
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  /// Base function to handle GET requests
  Future<dynamic> get(String path,
      {Map<String, String>? queryParameters}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$path')
          .replace(queryParameters: queryParameters);

      if (kDebugMode) debugPrint('ðŸŒ GET: $uri');

      final response = await http
          .get(uri, headers: _getHeaders())
          .timeout(ApiConfig.connectTimeout);
      return _processResponse(response);
    } on SocketException {
      throw ApiException('No internet connection. Please check your network.');
    } on TimeoutException {
      throw ApiException('Request timed out. Please try again.');
    } catch (e) {
      if (e is ApiException) rethrow;
      final msg = e.toString();
      if (msg.contains('Failed to fetch')) {
        throw ApiException(
            'Client failed to reach API. Possible CORS block or server down.');
      }
      throw ApiException('Unexpected error: $msg');
    }
  }

  /// Base function to handle POST requests
  Future<dynamic> post(String path, dynamic data) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$path');

      if (kDebugMode) {
        debugPrint('ðŸŒ POST: $uri');
        debugPrint('ðŸ“¦ BODY: ${jsonEncode(data)}');
      }

      final response = await http
          .post(
            uri,
            headers: _getHeaders(),
            body: jsonEncode(data),
          )
          .timeout(ApiConfig.connectTimeout);
      return _processResponse(response);
    } on SocketException {
      throw ApiException('No internet connection. Please check your network.');
    } on TimeoutException {
      throw ApiException('Request timed out. Please try again.');
    } catch (e) {
      if (e is ApiException) rethrow;
      final msg = e.toString();
      if (msg.contains('Failed to fetch')) {
        throw ApiException(
            'Client failed to reach API. Possible CORS block or server down.');
      }
      throw ApiException('Unexpected error: $msg');
    }
  }

  /// Handles response status codes and JSON parsing
  dynamic _processResponse(http.Response response) {
    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // If data is wrapped in a "data" key, extract it
      if (body is Map<String, dynamic> && body.containsKey('data')) {
        return body['data'];
      }
      return body;
    } else {
      if (response.statusCode == 401) {
        onUnauthorized?.call();
      }
      // Handle error messages from Laravel if present
      String errorMsg = 'Error: ${response.statusCode}';
      if (body is Map<String, dynamic>) {
        // Prefer specific message if available
        errorMsg = body['message'] ?? body['error'] ?? errorMsg;
        // Extract first validation error for 422
        if (response.statusCode == 422) {
          final errors = body['errors'];
          if (errors is Map) {
            for (final entry in errors.entries) {
              final val = entry.value;
              if (val is List && val.isNotEmpty) {
                errorMsg = val.first.toString();
                break;
              } else if (val is String && val.isNotEmpty) {
                errorMsg = val;
                break;
              }
            }
          }
        }
      }
      throw ApiException(errorMsg, response.statusCode);
    }
  }

  // Helper functions for specific endpoints
  Future<List<dynamic>> getCategories() async {
    final data = await get(ApiConstants.categories);
    if (data is List) return data;
    throw ApiException('Invalid categories data format');
  }

  Future<List<dynamic>> getProducts() async {
    final data = await get(ApiConstants.products);
    if (data is List) return data;
    throw ApiException('Invalid products data format');
  }

  Future<List<dynamic>> getProductsFiltered({
    int? page,
    String? search,
    String? categoryId,
    int? perPage,
  }) async {
    final params = <String, String>{};
    if (page != null) params['page'] = page.toString();
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (categoryId != null && categoryId.isNotEmpty) {
      params['category_id'] = categoryId;
    }
    params['per_page'] = (perPage ?? _defaultPerPage).toString();

    final data = await get(ApiConstants.products, queryParameters: params);
    if (data is List) return data;
    // If paginated, Laravel might return a map with data: [...]
    if (data is Map && data.containsKey('data')) {
      final inner = data['data'];
      if (inner is List) return inner;
    }
    return [];
  }

  Future<Map<String, dynamic>> login(String login, String password) async {
    final payload = <String, dynamic>{
      'login': login,
      'password': password,
    };
    if (login.contains('@')) {
      payload['email'] = login;
    } else {
      payload['phone'] = login;
    }
    final res = await post(ApiConstants.login, payload);
    if (res is Map<String, dynamic>) return res;
    throw ApiException('Invalid login response');
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> payload) async {
    final res = await post(ApiConstants.register, payload);
    if (res is Map<String, dynamic>) return res;
    throw ApiException('Invalid register response');
  }

  /// Base function to handle PUT requests
  Future<dynamic> put(String path, dynamic data) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$path');
      if (kDebugMode) {
        debugPrint('ðŸ“ PUT: $uri');
        debugPrint('ðŸ“¦ BODY: ${jsonEncode(data)}');
      }
      final response = await http
          .put(
            uri,
            headers: _getHeaders(),
            body: jsonEncode(data),
          )
          .timeout(ApiConfig.connectTimeout);
      return _processResponse(response);
    } on SocketException {
      throw ApiException('No internet connection. Please check your network.');
    } on TimeoutException {
      throw ApiException('Request timed out. Please try again.');
    } catch (e) {
      if (e is ApiException) rethrow;
      final msg = e.toString();
      if (msg.contains('Failed to fetch')) {
        throw ApiException(
            'Client failed to reach API. Possible CORS block or server down.');
      }
      throw ApiException('Unexpected error: $msg');
    }
  }

  // DELETE helper
  Future<dynamic> delete(String path) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$path');
      if (kDebugMode) debugPrint('ðŸ—‘ï¸ DELETE: $uri');
      final response = await http
          .delete(uri, headers: _getHeaders())
          .timeout(ApiConfig.connectTimeout);
      return _processResponse(response);
    } on SocketException {
      throw ApiException('No internet connection. Please check your network.');
    } on TimeoutException {
      throw ApiException('Request timed out. Please try again.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error: $e');
    }
  }

  // Phone codes
  Future<List<dynamic>> getPhoneCodes() async {
    final data = await get(ApiConstants.phoneCodes);
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'];
    return [];
  }

  // Current authenticated user
  Future<UserModel> getUser() async {
    final data = await get(ApiConstants.user);
    if (data is Map<String, dynamic>) {
      final map =
          data['data'] is Map ? Map<String, dynamic>.from(data['data']) : data;
      return UserModel.fromJson(map);
    }
    throw ApiException('Invalid user response');
  }

  // OTP Email flows
  Future<Map<String, dynamic>> verifyOtpEmail(
      String email, String otpCode) async {
    final res = await post(ApiConstants.verifyOtp, {
      'email': email,
      'otp_code': otpCode,
    });
    if (res is Map<String, dynamic>) return res;
    throw ApiException('Invalid verify OTP response');
  }

  Future<Map<String, dynamic>> resendOtpEmail(String email) async {
    final res = await post(ApiConstants.resendOtp, {'email': email});
    if (res is Map<String, dynamic>) return res;
    throw ApiException('Invalid resend OTP response');
  }

  // Generic OTP helpers (ID-based)
  Future<Map<String, dynamic>> verifyOtp(dynamic userId, String otpCode) async {
    final res = await post(ApiConstants.verifyOtp, {
      'user_id': userId,
      'otp_code': otpCode,
    });
    if (res is Map<String, dynamic>) return res;
    throw ApiException('Invalid verify OTP response');
  }

  Future<Map<String, dynamic>> resendOtp(dynamic userId) async {
    final res = await post(ApiConstants.resendOtp, {
      'user_id': userId,
    });
    if (res is Map<String, dynamic>) return res;
    throw ApiException('Invalid resend OTP response');
  }

  // FCM device token management
  Future<void> submitFCMToken(String fcmToken) async {
    // Prefer users fcm-token if available; fallback to legacy save-device-token
    try {
      await post(ApiConstants.usersFcmToken, {
        'device_token': fcmToken,
        'platform': 'android',
      });
      return;
    } catch (_) {}
    await post(ApiConstants.saveDeviceToken, {
      'device_token': fcmToken,
      'platform': 'android',
    });
  }

  Future<void> revokeFCMToken(String fcmToken) async {
    // Try conventional revoke path; ignore non-200 errors silently
    try {
      await post('${ApiConstants.saveDeviceToken}/revoke', {
        'device_token': fcmToken,
      });
    } catch (_) {
      // Not critical
    }
  }

  // Multipart helper (keeps compatibility with existing provider code)
  Future<dio.Response> postMultipart(String path, dio.FormData form) async {
    final options = dio.BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      headers: {
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      },
      contentType: 'multipart/form-data',
      followRedirects: false,
      validateStatus: (code) => code != null && code >= 200 && code < 500,
    );
    final client = dio.Dio(options);
    final res = await client.post(path, data: form);
    if (res.statusCode == 401) {
      onUnauthorized?.call();
      throw ApiException('Unauthorized', 401);
    }
    if (res.statusCode != null &&
        res.statusCode! >= 200 &&
        res.statusCode! < 300) {
      return res;
    }
    final data = res.data;
    var msg = 'Error: ${res.statusCode}';
    if (data is Map) {
      msg = data['message']?.toString() ?? data['error']?.toString() ?? msg;
    }
    throw ApiException(msg, res.statusCode);
  }

  // Category specific fetch
  Future<List<dynamic>> getProductsByCategory(String categoryId) async {
    // Primary approach: /products?category_id={id}
    try {
      final data = await get(ApiConstants.products, queryParameters: {
        'category_id': categoryId,
        'per_page': _defaultPerPage.toString(),
      });
      if (data is List) return data;
      if (data is Map && data['data'] is List) return data['data'];
    } catch (_) {}
    // Secondary: /products/category/{id}
    try {
      final data = await get('${ApiConstants.productsByCategory}/$categoryId');
      if (data is List) return data;
      if (data is Map && data['data'] is List) return data['data'];
    } catch (_) {}
    // Fallback (if backend exposes /categories/{id}/products)
    try {
      final data = await get('/categories/$categoryId/products');
      if (data is List) return data;
      if (data is Map && data['data'] is List) return data['data'];
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> getCategoryWithProducts(
    dynamic category, {
    int? limit,
  }) async {
    final params = <String, String>{};
    params['limit'] = (limit ?? _defaultCategoryProductsLimit).toString();
    final data = await get('${ApiConstants.categories}/$category',
        queryParameters: params);
    if (data is Map<String, dynamic>) return data;
    if (data is Map && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data']);
    }
    throw ApiException('Invalid category detail response');
  }

  // Products helpers
  Future<Map<String, dynamic>> getProductById(int id) async {
    final data = await get('${ApiConstants.products}/$id');
    if (data is Map<String, dynamic>) {
      return data['data'] is Map
          ? Map<String, dynamic>.from(data['data'])
          : data;
    }
    throw ApiException('Invalid product response');
  }

  Future<List<dynamic>> getNewArrivals() async {
    final data = await get(ApiConstants.productsNewArrivals);
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'];
    return [];
  }

  Future<List<dynamic>> getFlashSale() async {
    final data = await get(ApiConstants.products,
        queryParameters: {'filter': 'flash-sale'});
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'];
    return [];
  }

  // Cart & Orders
  Future<Map<String, dynamic>> getCart() async {
    final data = await get(ApiConstants.cart);
    if (data is Map<String, dynamic>) return data;
    throw ApiException('Invalid cart response');
  }

  Future<Map<String, dynamic>> cartAdd({
    required int productId,
    required int quantity,
  }) async {
    final res = await post(ApiConstants.cartAdd, {
      'product_id': productId,
      'quantity': quantity,
    });
    if (res is Map<String, dynamic>) return res;
    throw ApiException('Invalid cart add response');
  }

  Future<List<dynamic>> getOrders() async {
    final data = await get(ApiConstants.orders);
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'];
    return [];
  }

  Future<Map<String, dynamic>> getOrder(dynamic id) async {
    final data = await get('${ApiConstants.orders}/$id');
    if (data is Map<String, dynamic>) {
      return data['data'] is Map
          ? Map<String, dynamic>.from(data['data'])
          : data;
    }
    throw ApiException('Invalid order response');
  }

  Future<Map<String, dynamic>> getOrderTrack(dynamic id) async {
    final path = ApiConstants.orderTrack.replaceFirst('{order}', '$id');
    final data = await get(path);
    if (data is Map<String, dynamic>) return data;
    throw ApiException('Invalid track response');
  }

  Future<Map<String, dynamic>> updateOrderLocation(
      dynamic id, Map<String, dynamic> payload) async {
    final path = ApiConstants.orderLocation.replaceFirst('{order}', '$id');
    final res = await post(path, payload);
    if (res is Map<String, dynamic>) return res;
    throw ApiException('Invalid location update response');
  }

  Future<Map<String, dynamic>> confirmOrderDelivery(dynamic id) async {
    final path =
        ApiConstants.orderConfirmDelivery.replaceFirst('{order}', '$id');
    final res = await post(path, {});
    if (res is Map<String, dynamic>) return res;
    throw ApiException('Invalid confirm delivery response');
  }

  Future<Map<String, dynamic>> checkout(Map<String, dynamic> payload) async {
    final res = await post(ApiConstants.ordersConfirm, payload);
    if (res is Map<String, dynamic>) return res;
    throw ApiException('Invalid checkout response');
  }

  // Auth & Settings
  Future<Map<String, dynamic>> firebaseLogin({
    required String firebaseUid,
    String? phone,
  }) async {
    final res = await post(ApiConstants.firebaseLogin, {
      'firebase_uid': firebaseUid,
      if (phone != null) 'phone': phone,
    });
    if (res is Map<String, dynamic>) return res;
    throw ApiException('Invalid firebase login response');
  }

  Future<void> logout() async {
    await post(ApiConstants.logout, {});
  }

  Future<Map<String, dynamic>> getSettingsPublic() async {
    final data = await get(ApiConstants.settingsPublic);
    if (data is Map<String, dynamic>) return data;
    throw ApiException('Invalid settings response');
  }

  // Notifications
  Future<List<dynamic>> getNotifications() async {
    final data = await get(ApiConstants.notifications);
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'];
    return [];
  }

  Future<void> markNotificationsRead() async {
    await post(ApiConstants.notificationsRead, {});
  }
}
