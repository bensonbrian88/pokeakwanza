import 'package:stynext/core/api/api_service.dart';
import 'package:stynext/core/architecture/result.dart';
import 'package:stynext/core/architecture/exceptions.dart';
import 'package:stynext/core/architecture/repositories.dart';
import 'package:stynext/models/user_model.dart';
import 'package:stynext/data/repositories/impl/product_repository_impl.dart';

/// Implementation of AuthRepository using API service
class AuthRepositoryImpl implements AuthRepository {
  final ApiService _apiService;

  AuthRepositoryImpl(this._apiService);

  @override
  Future<Result<Map<String, dynamic>>> login(
    String email,
    String password,
  ) async {
    try {
      // Validate inputs
      if (email.isEmpty) {
        return Failure(ValidationException(message: 'Email is required'));
      }
      if (password.isEmpty) {
        return Failure(ValidationException(message: 'Password is required'));
      }
      if (!_isValidEmail(email)) {
        return Failure(ValidationException(message: 'Invalid email format'));
      }

      final response = await _apiService.login(email, password);

      return Success(response);
    } on Exception catch (e, st) {
      return Failure(ExceptionMapper.map(e, st));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> register(
    Map<String, dynamic> payload,
  ) async {
    try {
      if (payload.isEmpty) {
        return Failure(
            ValidationException(message: 'Registration data required'));
      }

      // Validate required fields
      final email = payload['email'];
      final password = payload['password'];
      final name = payload['name'];

      if (email is! String || email.isEmpty) {
        return Failure(ValidationException(message: 'Email is required'));
      }
      if (!_isValidEmail(email)) {
        return Failure(ValidationException(message: 'Invalid email format'));
      }
      if (password is! String || password.isEmpty) {
        return Failure(ValidationException(message: 'Password is required'));
      }
      if (password.length < 6) {
        return Failure(ValidationException(
          message: 'Password must be at least 6 characters',
        ));
      }
      if (name is! String || name.isEmpty) {
        return Failure(ValidationException(message: 'Name is required'));
      }

      final response = await _apiService.register(payload);

      return Success(response);
    } on Exception catch (e, st) {
      return Failure(ExceptionMapper.map(e, st));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> firebaseLogin({
    required String firebaseUid,
    String? phone,
  }) async {
    try {
      if (firebaseUid.isEmpty) {
        return Failure(ValidationException(message: 'Firebase UID required'));
      }

      final response = await _apiService.firebaseLogin(
        firebaseUid: firebaseUid,
        phone: phone,
      );

      return Success(response);
    } on Exception catch (e, st) {
      return Failure(ExceptionMapper.map(e, st));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> verifyOtp(
    int userId,
    String otpCode,
  ) async {
    try {
      if (userId <= 0) {
        return Failure(ValidationException(message: 'Invalid user ID'));
      }
      if (otpCode.isEmpty) {
        return Failure(ValidationException(message: 'OTP code required'));
      }
      if (otpCode.length != 6 || !_isNumeric(otpCode)) {
        return Failure(ValidationException(message: 'Invalid OTP format'));
      }

      final response = await _apiService.verifyOtp(userId, otpCode);

      return Success(response);
    } on Exception catch (e, st) {
      return Failure(ExceptionMapper.map(e, st));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> resendOtp(int userId) async {
    try {
      if (userId <= 0) {
        return Failure(ValidationException(message: 'Invalid user ID'));
      }

      final response = await _apiService.resendOtp(userId);

      return Success(response);
    } on Exception catch (e, st) {
      return Failure(ExceptionMapper.map(e, st));
    }
  }

  @override
  Future<Result<List<dynamic>>> getPhoneCodes() async {
    try {
      final response = await _apiService.getPhoneCodes();

      return Success(response);
    } on Exception catch (e, st) {
      return Failure(ExceptionMapper.map(e, st));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _apiService.logout();
      return const Success(null);
    } on Exception catch (e, st) {
      return Failure(ExceptionMapper.map(e, st));
    }
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return regex.hasMatch(email);
  }

  bool _isNumeric(String s) => int.tryParse(s) != null;
}

/// Implementation of UserRepository using API service
class UserRepositoryImpl implements UserRepository {
  final ApiService _apiService;

  UserRepositoryImpl(this._apiService);

  @override
  Future<Result<UserModel>> getUser() async {
    try {
      final user = await _apiService.getUser();

      return Success(user);
    } on Exception catch (e, st) {
      return Failure(ExceptionMapper.map(e, st));
    }
  }

  @override
  Future<Result<UserModel>> updateProfile({
    String? name,
    String? phone,
  }) async {
    try {
      // Validate inputs if provided
      if (name != null && name.isEmpty) {
        return Failure(ValidationException(message: 'Name cannot be empty'));
      }
      if (phone != null && phone.isEmpty) {
        return Failure(ValidationException(message: 'Phone cannot be empty'));
      }

      final user = await _apiService.getUser();

      return Success(user);
    } on Exception catch (e, st) {
      return Failure(ExceptionMapper.map(e, st));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getUserSettings() async {
    try {
      final response = await _apiService.getSettingsPublic();

      return Success(response);
    } on Exception catch (e, st) {
      return Failure(ExceptionMapper.map(e, st));
    }
  }
}

/// Implementation of ShippingAddressRepository using API service
class ShippingAddressRepositoryImpl implements ShippingAddressRepository {
  final ApiService _apiService;

  ShippingAddressRepositoryImpl(this._apiService);

  @override
  Future<Result<List<dynamic>>> getAddresses() async {
    try {
      final response = await _apiService.get('/shipping-addresses');

      final data = response.data is Map
          ? response.data['data'] ?? response.data
          : response.data;
      if (data is! List) {
        return Failure(DataException.parseError('Addresses must be a list'));
      }

      return Success(data);
    } on Exception catch (e, st) {
      return Failure(ExceptionMapper.map(e, st));
    }
  }

  @override
  Future<Result<dynamic>> addAddress(Map<String, dynamic> payload) async {
    try {
      if (payload.isEmpty) {
        return Failure(ValidationException(message: 'Address data required'));
      }

      final response = await _apiService.post('/shipping-addresses', payload);

      if (response.data is! Map<String, dynamic>) {
        return Failure(DataException.parseError('Invalid response format'));
      }

      return Success(response.data);
    } on Exception catch (e, st) {
      return Failure(ExceptionMapper.map(e, st));
    }
  }

  @override
  Future<Result<dynamic>> updateAddress(
    int id,
    Map<String, dynamic> payload,
  ) async {
    try {
      if (id <= 0) {
        return Failure(ValidationException(message: 'Invalid address ID'));
      }
      if (payload.isEmpty) {
        return Failure(ValidationException(message: 'Address data required'));
      }

      final response =
          await _apiService.put('/shipping-addresses/$id', payload);

      if (response.data is! Map<String, dynamic>) {
        return Failure(DataException.parseError('Invalid response format'));
      }

      return Success(response.data);
    } on Exception catch (e, st) {
      return Failure(ExceptionMapper.map(e, st));
    }
  }

  @override
  Future<Result<void>> deleteAddress(int id) async {
    try {
      if (id <= 0) {
        return Failure(ValidationException(message: 'Invalid address ID'));
      }

      await _apiService.delete('/shipping-addresses/$id');
      return const Success(null);
    } on Exception catch (e, st) {
      return Failure(ExceptionMapper.map(e, st));
    }
  }
}

/// Implementation of NotificationRepository using API service
class NotificationRepositoryImpl implements NotificationRepository {
  final ApiService _apiService;

  NotificationRepositoryImpl(this._apiService);

  @override
  Future<Result<List<dynamic>>> getNotifications() async {
    try {
      final response = await _apiService.getNotifications();

      return Success(response);
    } on Exception catch (e, st) {
      return Failure(ExceptionMapper.map(e, st));
    }
  }

  @override
  Future<Result<void>> markNotificationsAsRead() async {
    try {
      await _apiService.markNotificationsRead();
      return const Success(null);
    } on Exception catch (e, st) {
      return Failure(ExceptionMapper.map(e, st));
    }
  }
}
