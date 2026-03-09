import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      return _handleDioException(error);
    } else if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return 'An unexpected error occurred. Please try again.';
  }

  static String _handleDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet and try again.';
      case DioExceptionType.sendTimeout:
        return 'Request timeout. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Response timeout. Please try again.';
      case DioExceptionType.badResponse:
        return _handleResponseError(error.response);
      case DioExceptionType.cancel:
        return 'Request cancelled.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network.';
      case DioExceptionType.badCertificate:
        return 'Security certificate error. Please try again later.';
      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return 'No internet connection. Please check your network.';
        }
        return 'Network error. Please try again.';
    }
  }

  static String _handleResponseError(Response? response) {
    if (response == null) {
      return 'Server error. Please try again later.';
    }

    final statusCode = response.statusCode ?? 0;
    final data = response.data;

    // Try to extract error message from response
    String? message;
    if (data is Map<String, dynamic>) {
      message = data['message'] ??
          data['error'] ??
          data['errors']?.toString() ??
          null;
    }

    switch (statusCode) {
      case 400:
        return message ?? 'Invalid request. Please check your input.';
      case 401:
        return 'Your session has expired. Please log in again.';
      case 403:
        return message ?? 'Access denied.';
      case 404:
        return 'Resource not found.';
      case 409:
        return message ?? 'Conflict with existing data.';
      case 422:
        return message ?? 'Invalid input. Please check your data.';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
      case 503:
      case 504:
        return 'Server is temporarily unavailable. Please try again later.';
      default:
        return message ?? 'An error occurred. Please try again.';
    }
  }

  static void logError(String tag, dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('[$tag] Error: $error');
      if (stackTrace != null) {
        print(stackTrace);
      }
    }
  }
}
