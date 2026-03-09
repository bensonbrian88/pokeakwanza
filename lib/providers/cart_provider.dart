import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stynext/models/cart_item.dart';
import 'package:stynext/models/product.dart';
import 'package:stynext/core/di/service_locator.dart';
import 'package:stynext/domain/usecases/usecases.dart';
import 'package:stynext/core/architecture/result.dart';

class CartState {
  final List<CartItem> items;
  const CartState({this.items = const []});
  int get itemCount => items.length;
  int get totalItems => items.fold<int>(0, (sum, item) => sum + item.quantity);
  double get totalAmount => items.fold<double>(
      0, (sum, it) => sum + (it.product.price * it.quantity));
  int quantityForProduct(int productId) {
    final idx = items.indexWhere((it) => it.product.id == productId);
    return idx >= 0 ? items[idx].quantity : 0;
  }

  double totalForProduct(int productId) {
    final idx = items.indexWhere((it) => it.product.id == productId);
    if (idx >= 0) {
      final item = items[idx];
      return item.product.price * item.quantity;
    }
    return 0.0;
  }

  CartState copyWith({List<CartItem>? items}) =>
      CartState(items: items ?? this.items);
}

class CartNotifier extends StateNotifier<CartState> {
  final FetchCartUseCase _fetchCart = getIt<FetchCartUseCase>();
  final AddToCartUseCase _addToCart = getIt<AddToCartUseCase>();
  final UpdateCartQuantityUseCase _updateQty =
      getIt<UpdateCartQuantityUseCase>();
  final RemoveFromCartUseCase _remove = getIt<RemoveFromCartUseCase>();
  final ClearCartUseCase _clear = getIt<ClearCartUseCase>();
  CartNotifier() : super(const CartState());

  Future<void> fetchCart() async {
    try {
      final result = await _fetchCart.call();
      result.fold(
        onSuccess: (data) {
          List<CartItem> list = [];
          final items = data['items'];
          if (items is List) {
            list = items
                .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          state = state.copyWith(items: list);
        },
        onFailure: (_) {},
      );
    } catch (_) {}
  }

  Future<void> addToCart(Product product, {int quantity = 1}) async {
    try {
      final result =
          await _addToCart.call(productId: product.id, quantity: quantity);
      result.fold(
        onSuccess: (_) async => await fetchCart(),
        onFailure: (_) {
          final idx =
              state.items.indexWhere((it) => it.product.id == product.id);
          if (idx >= 0) {
            final list = [...state.items];
            list[idx].quantity += quantity;
            state = state.copyWith(items: list);
          } else {
            state = state.copyWith(items: [
              ...state.items,
              CartItem(product: product, quantity: quantity)
            ]);
          }
        },
      );
    } catch (_) {}
  }

  Future<void> updateQuantity(int productId, int quantity) async {
    try {
      final result =
          await _updateQty.call(productId: productId, quantity: quantity);
      result.fold(
        onSuccess: (_) async => await fetchCart(),
        onFailure: (_) {
          final idx =
              state.items.indexWhere((it) => it.product.id == productId);
          if (idx >= 0) {
            final list = [...state.items];
            list[idx].quantity = quantity < 1 ? 1 : quantity;
            state = state.copyWith(items: list);
          }
        },
      );
    } catch (_) {}
  }

  Future<void> removeItem(int productId) async {
    try {
      final result = await _remove.call(productId);
      result.fold(
        onSuccess: (_) async => await fetchCart(),
        onFailure: (_) {
          state = state.copyWith(
              items: state.items
                  .where((it) => it.product.id != productId)
                  .toList());
        },
      );
    } catch (_) {}
  }

  Future<void> clearCart() async {
    try {
      final result = await _clear.call();
      result.fold(
        onSuccess: (_) => state = state.copyWith(items: []),
        onFailure: (_) => state = state.copyWith(items: []),
      );
    } catch (_) {
      state = state.copyWith(items: []);
    }
  }
}

final cartProvider =
    StateNotifierProvider<CartNotifier, CartState>((ref) => CartNotifier());
