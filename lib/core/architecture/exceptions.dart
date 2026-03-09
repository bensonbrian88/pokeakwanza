/// Base exception for all app errors
abstract class AppException implements Exception {
  final String message;
  final dynamic originalException;
  final StackTrace? stackTrace;

  AppException({
    required this.message,
    this.originalException,
    this.stackTrace,
  });

  @override
  String toString() => message;
}

/// Network related exceptions
class NetworkException extends AppException {
  NetworkException({
    required String message,
    dynamic originalException,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          originalException: originalException,
          stackTrace: stackTrace,
        );

  factory NetworkException.noInternet() => NetworkException(
        message: 'No internet connection. Please check your network.',
      );

  factory NetworkException.timeout() => NetworkException(
        message: 'Request timed out. Please try again.',
      );

  factory NetworkException.connectionError(String details) => NetworkException(
        message: 'Connection error: $details',
      );
}

/// Server related exceptions
class ServerException extends AppException {
  final int? statusCode;

  ServerException({
    required String message,
    this.statusCode,
    dynamic originalException,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          originalException: originalException,
          stackTrace: stackTrace,
        );

  factory ServerException.unauthorized() => ServerException(
        message: 'Your session has expired. Please log in again.',
        statusCode: 401,
      );

  factory ServerException.forbidden() => ServerException(
        message: 'Access denied.',
        statusCode: 403,
      );

  factory ServerException.notFound() => ServerException(
        message: 'Resource not found.',
        statusCode: 404,
      );

  factory ServerException.conflict(String message) => ServerException(
        message: message,
        statusCode: 409,
      );

  factory ServerException.validationError(String message) => ServerException(
        message: message,
        statusCode: 422,
      );

  factory ServerException.internal(String message) => ServerException(
        message: message,
        statusCode: 500,
      );

  factory ServerException.unavailable() => ServerException(
        message: 'Server is temporarily unavailable. Please try again later.',
        statusCode: 503,
      );
}

/// Validation related exceptions
class ValidationException extends AppException {
  final Map<String, List<String>>? errors;

  ValidationException({
    required String message,
    this.errors,
    dynamic originalException,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          originalException: originalException,
          stackTrace: stackTrace,
        );
}

/// Data parsing related exceptions
class DataException extends AppException {
  DataException({
    required String message,
    dynamic originalException,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          originalException: originalException,
          stackTrace: stackTrace,
        );

  factory DataException.parseError(String details) => DataException(
        message: 'Failed to parse data: $details',
      );

  factory DataException.nullValue(String field) => DataException(
        message: 'Unexpected null value for field: $field',
      );
}

/// Cache related exceptions
class CacheException extends AppException {
  CacheException({
    required String message,
    dynamic originalException,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          originalException: originalException,
          stackTrace: stackTrace,
        );

  factory CacheException.notFound() => CacheException(
        message: 'Data not found in cache.',
      );

  factory CacheException.write() => CacheException(
        message: 'Failed to write data to cache.',
      );
}

/// Authentication related exceptions
class AuthException extends AppException {
  AuthException({
    required String message,
    dynamic originalException,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          originalException: originalException,
          stackTrace: stackTrace,
        );

  factory AuthException.invalidCredentials() => AuthException(
        message: 'Invalid email or password.',
      );

  factory AuthException.accountLocked() => AuthException(
        message: 'Your account has been locked.',
      );

  factory AuthException.notVerified() => AuthException(
        message: 'Please verify your email to continue.',
      );
}

/// Unknown/unexpected exceptions
class UnknownException extends AppException {
  UnknownException({
    required String message,
    dynamic originalException,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          originalException: originalException,
          stackTrace: stackTrace,
        );
}
