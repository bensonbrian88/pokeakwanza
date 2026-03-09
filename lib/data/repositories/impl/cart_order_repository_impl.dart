import 'package:stynext/core/api/api_service.dart';
import 'package:stynext/core/architecture/result.dart';
import 'package:stynext/core/architecture/exceptions.dart';
import 'package:stynext/core/architecture/repositories.dart';
import 'package:stynext/data/repositories/impl/product_repository_impl.dart';
import 'package:stynext/core/api/api_constants.dart';

/// Implementation of CartRepository using API service
class CartRepositoryImpl implements CartRepository {
  final ApiService _apiService;

  CartRepositoryImpl(this._apiService);

  @override
  Future<Result<Map<String, dynamic>>> getCart() async {
    try {
      final response = await _apiService.getCart();

      return Success(response);
    } on Exception catch (e, st) {
      return Failure(ExceptionMapper.map(e, st));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> addToCart({
    required int productId,
    required int quantity,
  }) async {
    try {
      // Validate inputs
      if (productId <= 0) {
        return Failure(ValidationException(
          message: 'Invalid product ID',
        ));
      }
      if (quantity <= 0) {
        return Failure(ValidationException(
          message: 'Quantity must be greater than 0',
        ));
      }

      final response = await _apiService.cartAdd(
        productId: productId,
        quantity: quantity,
      );

      return Success(response);
    } on Exception catch (e, st) {
      return Failure(ExceptionMapper.map(e, st));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> updateQuantity({
    required int productId,
    required int quantity,
  }) async {
    try {
      if (productId <= 0) {
        return Failure(ValidationException(
          message: 'Invalid product ID',
        ));
      }
      if (quantity < 0) {
        return Failure(ValidationException(
          message: 'Quantity cannot be negative',
        ));
      }

      final response = await _apiService.post(
        '/cart/update',
        {'product_id': productId, 'quantity': quantity},
      );

      if (response.data is! Map<String, dynamic>) {
        return Failure(DataException.parseError('Invalid response format'));
      }

      return Success(response.data as Map<String, dynamic>);
    } on Exception catch (e, st) {
      return Failure(ExceptionMapper.map(e, st));
    }
  }

  @override
  Future<Result<void>> removeFromCart(int productId) async {
    try {
      if (productId <= 0) {
        return Failure(ValidationException(
          message: 'Invalid product ID',
        ));
      }

      await _apiService.delete('${ApiConstants.cart}/$productId');
      return const Success(null);
    } on Exception catch (e, st) {
      return Failure(ExceptionMapper.map(e, st));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getCartSummary() async {
    try {
      final response = await _apiService.post('/cart/summary', {});

      if (response.data is! Map<String, dynamic>) {
        return Failure(DataException.parseError('Invalid response format'));
      }

      return Success(response.data as Map<String, dynamic>);
    } on Exception catch (e, st) {
      return Failure(ExceptionMapper.map(e, st));
    }
  }

  @override
  Future<Result<void>> clearCart() async {
    try {
      await _apiService.post('/cart/clear', {});
      return const Success(null);
    } on Exception catch (e, st) {
      return Failure(ExceptionMapper.map(e, st));
    }
  }
}

/// Implementation of OrderRepository using API service
class OrderRepositoryImpl implements OrderRepository {
  final ApiService _apiService;

  OrderRepositoryImpl(this._apiService);

  @override
  Future<Result<List<dynamic>>> getOrders() async {
    try {
      final response = await _apiService.getOrders();

      return Success(response);
    } on Exception catch (e, st) {
      return Failure(ExceptionMapper.map(e, st));
    }
  }

  @override
  Future<Result<int?>> checkout(String paymentMethod) async {
    try {
      if (paymentMethod.isEmpty) {
        return Failure(ValidationException(
          message: 'Payment method cannot be empty',
        ));
      }

      final response =
          await _apiService.checkout({'payment_method': paymentMethod});

      final orderId = response['order_id'] ?? response['id'];
      return Success(orderId as int?);
    } on Exception catch (e, st) {
      return Failure(ExceptionMapper.map(e, st));
    }
  }

  @override
  Future<Result<dynamic>> getOrderDetail(int orderId) async {
    try {
      if (orderId <= 0) {
        return Failure(ValidationException(
          message: 'Invalid order ID',
        ));
      }

      final response = await _apiService.getOrder(orderId);
      return Success(response);
    } on Exception catch (e, st) {
      return Failure(ExceptionMapper.map(e, st));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> createOrder(
    Map<String, dynamic> payload,
  ) async {
    try {
      if (payload.isEmpty) {
        return Failure(ValidationException(
          message: 'Order data cannot be empty',
        ));
      }

      final response = await _apiService.post('/orders', payload);

      if (response.data is! Map<String, dynamic>) {
        return Failure(DataException.parseError('Invalid response format'));
      }

      return Success(response.data as Map<String, dynamic>);
    } on Exception catch (e, st) {
      return Failure(ExceptionMapper.map(e, st));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> confirmOrder(int orderId) async {
    try {
      if (orderId <= 0) {
        return Failure(ValidationException(
          message: 'Invalid order ID',
        ));
      }

      final response = await _apiService.post(
        '/orders/confirm',
        {'order_id': orderId},
      );

      if (response.data is! Map<String, dynamic>) {
        return Failure(DataException.parseError('Invalid response format'));
      }

      return Success(response.data as Map<String, dynamic>);
    } on Exception catch (e, st) {
      return Failure(ExceptionMapper.map(e, st));
    }
  }
}
