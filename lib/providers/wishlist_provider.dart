import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stynext/models/product.dart';
import 'package:stynext/core/di/service_locator.dart';
import 'package:stynext/domain/usecases/usecases.dart';
import 'package:stynext/core/cache/cache_service.dart';

class WishlistState {
  final bool loading;
  final List<Product> items;
  final String? error;
  const WishlistState({
    this.loading = false,
    this.items = const [],
    this.error,
  });
  WishlistState copyWith({
    bool? loading,
    List<Product>? items,
    String? error,
  }) {
    return WishlistState(
      loading: loading ?? this.loading,
      items: items ?? this.items,
      error: error,
    );
  }
}

class WishlistNotifier extends StateNotifier<WishlistState> {
  final FetchProductDetailUseCase _fetchProductDetail =
      getIt<FetchProductDetailUseCase>();
  WishlistNotifier() : super(const WishlistState());

  Future<void> init() async {
    await CacheService.init();
    final ids = CacheService.getWishlistIds();
    final list = <Product>[];
    for (final id in ids) {
      final res = await _fetchProductDetail.call(id);
      res.fold(
        onSuccess: (p) => list.add(p),
        onFailure: (_) {},
      );
    }
    state = state.copyWith(items: list);
  }

  Future<void> addByProductId(int id) async {
    state = state.copyWith(loading: true, error: null);
    final res = await _fetchProductDetail.call(id);
    res.fold(
      onSuccess: (p) async {
        final list = [...state.items, p];
        state = state.copyWith(loading: false, items: list);
        final ids = list.map((e) => e.id).toList();
        await CacheService.putWishlistIds(ids);
      },
      onFailure: (e) {
        state = state.copyWith(loading: false, error: e.toString());
      },
    );
  }

  Future<void> removeByProductId(int id) async {
    final list = state.items.where((p) => p.id != id).toList();
    state = state.copyWith(items: list);
    final ids = list.map((e) => e.id).toList();
    await CacheService.putWishlistIds(ids);
  }

  Future<void> clear() async {
    state = const WishlistState(items: []);
    await CacheService.putWishlistIds([]);
  }
}

final wishlistProvider = StateNotifierProvider<WishlistNotifier, WishlistState>(
    (ref) => WishlistNotifier());
