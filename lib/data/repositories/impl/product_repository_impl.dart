import 'dart:io';
import 'package:dio/dio.dart';
import 'package:stynext/core/api/api_service.dart';
import 'package:stynext/core/architecture/result.dart';
import 'package:stynext/core/architecture/exceptions.dart';
import 'package:stynext/core/architecture/repositories.dart';
import 'package:stynext/models/product.dart';
import 'package:stynext/models/category.dart';

/// Exception mapper for converting DioException to AppException
class ExceptionMapper {
  static AppException map(dynamic exception, [StackTrace? stackTrace]) {
    if (exception is AppException) {
      return exception;
    }

    if (exception is DioException) {
      return _mapDioException(exception, stackTrace);
    }

    if (exception is SocketException) {
      return NetworkException.noInternet();
    }

    return UnknownException(
      message: exception.toString(),
      originalException: exception,
      stackTrace: stackTrace,
    );
  }

  static AppException _mapDioException(
    DioException error,
    StackTrace? stackTrace,
  ) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException.timeout();

      case DioExceptionType.connectionError:
        return NetworkException.noInternet();

      case DioExceptionType.badResponse:
        return _mapStatusCode(error.response, stackTrace);

      case DioExceptionType.badCertificate:
        return NetworkException(
          message: 'SSL certificate error',
          originalException: error,
          stackTrace: stackTrace,
        );

      case DioExceptionType.cancel:
        return NetworkException(
          message: 'Request cancelled',
          originalException: error,
          stackTrace: stackTrace,
        );

      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return NetworkException.noInternet();
        }
        return UnknownException(
          message: error.message ?? 'Unknown error occurred',
          originalException: error,
          stackTrace: stackTrace,
        );
    }
  }

  static AppException _mapStatusCode(
    Response? response,
    StackTrace? stackTrace,
  ) {
    if (response == null) {
      return ServerException.internal('No response from server');
    }

    final statusCode = response.statusCode ?? 500;
    final data = response.data;
    String message = 'Server error';

    if (data is Map<String, dynamic>) {
      message = data['message'] ??
          data['error'] ??
          data['errors']?.toString() ??
          message;
    }

    switch (statusCode) {
      case 400:
        return ServerException(
          message: message,
          statusCode: 400,
          originalException: response,
          stackTrace: stackTrace,
        );

      case 401:
        return ServerException.unauthorized();

      case 403:
        return ServerException.forbidden();

      case 404:
        return ServerException.notFound();

      case 409:
        return ServerException.conflict(message);

      case 422:
        return ValidationException(
          message: message,
          originalException: response,
          stackTrace: stackTrace,
        );

      case 429:
        return ServerException(
          message: 'Too many requests. Please try again later.',
          statusCode: 429,
          originalException: response,
          stackTrace: stackTrace,
        );

      case 500:
      case 502:
      case 503:
        return ServerException.unavailable();

      default:
        return ServerException(
          message: message,
          statusCode: statusCode,
          originalException: response,
          stackTrace: stackTrace,
        );
    }
  }
}

/// Implementation of ProductRepository using API service
class ProductRepositoryImpl implements ProductRepository {
  final ApiService _apiService;

  ProductRepositoryImpl(this._apiService);

  @override
  Future<Result<List<Product>>> getProducts({
    int? page,
    String? search,
    String? categoryId,
    int? perPage,
  }) async {
    try {
      final response = await _apiService.getProductsFiltered(
        page: page,
        search: search,
        categoryId: categoryId,
        perPage: perPage,
      );

      final products = (response)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();

      return Success(products);
    } on Exception catch (e, st) {
      return Failure(ExceptionMapper.map(e, st));
    }
  }

  @override
  Future<Result<Product>> getProductById(int id) async {
    try {
      final response = await _apiService.getProductById(id);
      final product = Product.fromJson(response);
      return Success(product);
    } on Exception catch (e, st) {
      return Failure(ExceptionMapper.map(e, st));
    }
  }

  @override
  Future<Result<List<Product>>> getNewArrivals() async {
    try {
      final response = await _apiService.getNewArrivals();
      final products = (response)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
      return Success(products);
    } on Exception catch (e, st) {
      return Failure(ExceptionMapper.map(e, st));
    }
  }

  @override
  Future<Result<List<Product>>> getProductsByCategory(String categoryId) async {
    try {
      final response = await _apiService.getProductsByCategory(categoryId);
      final products = (response)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
      return Success(products);
    } on Exception catch (e, st) {
      return Failure(ExceptionMapper.map(e, st));
    }
  }

  @override
  Future<Result<List<Product>>> getFlashSale() async {
    try {
      final response = await _apiService.getFlashSale();
      final products = (response)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
      return Success(products);
    } on Exception catch (e, st) {
      return Failure(ExceptionMapper.map(e, st));
    }
  }
}

/// Implementation of CategoryRepository using API service
class CategoryRepositoryImpl implements CategoryRepository {
  final ApiService _apiService;

  CategoryRepositoryImpl(this._apiService);

  @override
  Future<Result<List<Category>>> getCategories() async {
    try {
      final response = await _apiService.getCategories();
      final categories = (response)
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList();
      return Success(categories);
    } on Exception catch (e, st) {
      return Failure(ExceptionMapper.map(e, st));
    }
  }

  @override
  Future<Result<Category>> getCategoryById(String id) async {
    try {
      final response = await _apiService.get('/categories/$id');
      final data = (response is Map && response['data'] is Map)
          ? Map<String, dynamic>.from(response['data'] as Map)
          : Map<String, dynamic>.from(response as Map<String, dynamic>);
      final category = Category.fromJson(data);
      return Success(category);
    } on Exception catch (e, st) {
      return Failure(ExceptionMapper.map(e, st));
    }
  }
}
