import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stynext/models/order.dart';
import 'package:stynext/core/di/service_locator.dart';
import 'package:stynext/domain/usecases/usecases.dart';
import 'package:stynext/core/api/api_service.dart';

class OrderState {
  final List<Order> orders;
  final bool isLoading;
  const OrderState({this.orders = const [], this.isLoading = false});
  OrderState copyWith({List<Order>? orders, bool? isLoading}) => OrderState(
      orders: orders ?? this.orders, isLoading: isLoading ?? this.isLoading);
}

class OrderNotifier extends StateNotifier<OrderState> {
  final FetchOrdersUseCase _fetchOrders = getIt<FetchOrdersUseCase>();
  final FetchOrderDetailUseCase _fetchOrderDetail =
      getIt<FetchOrderDetailUseCase>();
  final CreateOrderUseCase _createOrder = getIt<CreateOrderUseCase>();
  OrderNotifier() : super(const OrderState());

  Future<void> fetchOrders() async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await _fetchOrders.call();
      result.fold(
        onSuccess: (data) {
          final list = data
              .whereType<Map<String, dynamic>>()
              .map((json) => Order.fromJson(json))
              .toList();
          state = state.copyWith(orders: list, isLoading: false);
        },
        onFailure: (_) {
          state = state.copyWith(orders: [], isLoading: false);
        },
      );
    } catch (_) {
      state = state.copyWith(orders: [], isLoading: false);
    }
  }

  Future<Order?> fetchOrderDetail(int orderId) async {
    try {
      final result = await _fetchOrderDetail.call(orderId);
      return result.getOrNull() is Map<String, dynamic>
          ? Order.fromJson(result.getOrNull() as Map<String, dynamic>)
          : null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> trackOrder(int orderId) async {
    try {
      return await ApiService.I.getOrderTrack(orderId);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkout(String paymentMethod,
      {String? deliveryDate,
      String? deliveryTime,
      String? deliveryTimeFrom,
      String? deliveryTimeTo,
      String? deliveryFrom,
      String? deliveryTo,
      int? addressId,
      bool payLater = false,
      required List<Map<String, dynamic>> cartItems}) async {
    try {
      final payload = <String, dynamic>{
        'payment_method': paymentMethod,
        'items': cartItems,
        if (addressId != null) 'address_id': addressId,
        if (deliveryDate != null) 'delivery_date': deliveryDate,
        if (deliveryTime != null) 'delivery_time': deliveryTime,
        if (deliveryTimeFrom != null) 'delivery_time_from': deliveryTimeFrom,
        if (deliveryTimeTo != null) 'delivery_time_to': deliveryTimeTo,
        if (deliveryFrom != null) 'delivery_from': deliveryFrom,
        if (deliveryTo != null) 'delivery_to': deliveryTo,
      };
      final result = await _createOrder.call(payload);
      final data = result.getOrNull();
      return data is Map<String, dynamic>
          ? Map<String, dynamic>.from(data)
          : {'success': false};
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateOrderLocation({
    required int orderId,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    try {
      return await ApiService.I.updateOrderLocation(orderId, {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> confirmDelivery(int orderId) async {
    try {
      return await ApiService.I.confirmOrderDelivery(orderId);
    } catch (e) {
      rethrow;
    }
  }
}

final orderProvider =
    StateNotifierProvider<OrderNotifier, OrderState>((ref) => OrderNotifier());
