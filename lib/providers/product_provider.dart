import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:stynext/domain/usecases/usecases.dart';
import 'package:stynext/core/di/service_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stynext/core/cache/cache_service.dart';
import 'package:stynext/models/product.dart';
import 'package:stynext/core/cache/app_cache_manager.dart';

class ProductState {
  final List<Product> products;
  final bool isLoading;
  final String? errorMessage;
  final int currentPage;
  final bool hasMore;
  final int? activeCategoryId;
  final String searchQuery;
  final List<Product> newArrivals;
  final Map<int, List<Product>> categoryCache;
  const ProductState({
    this.products = const [],
    this.isLoading = false,
    this.errorMessage,
    this.currentPage = 1,
    this.hasMore = true,
    this.activeCategoryId,
    this.searchQuery = '',
    this.newArrivals = const [],
    this.categoryCache = const {},
  });
  ProductState copyWith({
    List<Product>? products,
    bool? isLoading,
    String? errorMessage,
    int? currentPage,
    bool? hasMore,
    int? activeCategoryId,
    String? searchQuery,
    List<Product>? newArrivals,
    Map<int, List<Product>>? categoryCache,
  }) {
    return ProductState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      activeCategoryId: activeCategoryId ?? this.activeCategoryId,
      searchQuery: searchQuery ?? this.searchQuery,
      newArrivals: newArrivals ?? this.newArrivals,
      categoryCache: categoryCache ?? this.categoryCache,
    );
  }
}

class ProductNotifier extends StateNotifier<ProductState> {
  final FetchProductsUseCase _fetchProducts = getIt<FetchProductsUseCase>();
  final FetchNewArrivalsUseCase _fetchNewArrivals =
      getIt<FetchNewArrivalsUseCase>();
  final FetchProductDetailUseCase _fetchProductDetail =
      getIt<FetchProductDetailUseCase>();
  final FetchProductsByCategoryUseCase _fetchByCategory =
      getIt<FetchProductsByCategoryUseCase>();
  ProductNotifier() : super(const ProductState());

  Future<void> fetchProducts({
    int? categoryId,
    String? search,
    bool loadMore = false,
    bool clearExisting = true,
  }) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      var nextPage = state.currentPage;
      if (!loadMore) {
        nextPage = 1;
        state = state.copyWith(
          products: clearExisting ? <Product>[] : state.products,
          hasMore: true,
          activeCategoryId: categoryId,
          searchQuery: search ?? '',
          currentPage: nextPage,
        );
      } else {
        nextPage = state.currentPage + 1;
        state = state.copyWith(currentPage: nextPage);
      }

      final result = await _fetchProducts.call(
        page: nextPage,
        search: state.searchQuery,
        categoryId: state.activeCategoryId?.toString(),
      );
      result.fold(
        onSuccess: (list) async {
          await CacheService.init();
          final items = list;
          final merged = loadMore ? [...state.products, ...items] : items;
          final int? catId = state.activeCategoryId;
          final newCache = Map<int, List<Product>>.from(state.categoryCache);
          if (catId != null) {
            newCache[catId] = merged;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
              'cached_products_cat_$catId',
              _encodeProducts(merged),
            );
            await CacheService.putProducts(
              'cat_$catId',
              merged.map((p) => p.toJson()).toList(),
            );
          } else {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
              'cached_products_all',
              _encodeProducts(merged),
            );
            await CacheService.putProducts(
              'all',
              merged.map((p) => p.toJson()).toList(),
            );
          }
          state = state.copyWith(
            products: merged,
            hasMore: items.isNotEmpty,
            isLoading: false,
            categoryCache: newCache,
          );
          _prefetchImages(merged);
        },
        onFailure: (error) async {
          await _loadProductsFromCache();
          await CacheService.init();
          final catId = state.activeCategoryId;
          final key = catId != null ? 'cat_$catId' : 'all';
          final cached = CacheService.getProducts(key);
          if (cached.isNotEmpty) {
            final items = cached
                .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
                .toList();
            state = state.copyWith(products: items);
          }
          final msg = error is Exception ? error.toString() : '$error';
          state = state.copyWith(
            isLoading: false,
            errorMessage: msg,
            hasMore: false,
          );
        },
      );
    } catch (e) {
      await _loadProductsFromCache();
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
        hasMore: false,
      );
    }
  }

  void selectCategory(int? categoryId) {
    if (categoryId == null) {
      state = state.copyWith(activeCategoryId: null);
      return;
    }
    // Show cached or locally filtered list immediately
    final cached = state.categoryCache[categoryId];
    if (cached != null && cached.isNotEmpty) {
      state = state.copyWith(
        activeCategoryId: categoryId,
        products: cached,
        isLoading: false,
      );
      _prefetchImages(cached);
      // Refresh in background without clearing UI
      fetchProducts(categoryId: categoryId, clearExisting: false);
      return;
    }
    // Fallback: filter current list for instant feedback
    final quick =
        state.products.where((p) => p.categoryId == categoryId).toList();
    if (quick.isNotEmpty) {
      state = state.copyWith(
        activeCategoryId: categoryId,
        products: quick,
        isLoading: false,
      );
      _prefetchImages(quick);
    } else {
      state = state.copyWith(activeCategoryId: categoryId);
    }
    // Fetch from backend without clearing current UI
    fetchProducts(categoryId: categoryId, clearExisting: false);
  }

  Future<void> fetchNewArrivals() async {
    try {
      final result = await _fetchNewArrivals.call();
      result.fold(
        onSuccess: (items) {
          state = state.copyWith(newArrivals: items);
          _prefetchImages(items);
        },
        onFailure: (_) {
          state = state.copyWith(newArrivals: []);
        },
      );
    } catch (_) {
      state = state.copyWith(newArrivals: []);
    }
  }

  void clearProducts() {
    state = state.copyWith(
      products: [],
      currentPage: 1,
      hasMore: true,
      activeCategoryId: null,
      searchQuery: '',
    );
  }

  Future<void> refreshProducts() async {
    await fetchProducts(
      categoryId: state.activeCategoryId,
      search: state.searchQuery,
      loadMore: false,
      clearExisting: true,
    );
  }

  Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      final result = await _fetchByCategory.call(categoryId);
      return result.getOrNull() ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<Product?> getProductById(int id) async {
    final res = await _fetchProductDetail.call(id);
    return res.getOrNull();
  }

  Future<Product?> getProductByCode(String code) async {
    try {
      final result =
          await _fetchProducts.call(search: code, page: 1, perPage: 1);
      final list = result.getOrNull();
      if (list != null && list.isNotEmpty) {
        return list.first;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> prefetchCategories(List<int> categoryIds,
      {int maxPerCategory = 24}) async {
    for (final id in categoryIds) {
      if (state.categoryCache[id]?.isNotEmpty == true) continue;
      try {
        final result = await _fetchByCategory.call(id.toString());
        final items = result.getOrNull() ?? [];
        final limited = items.length > maxPerCategory
            ? items.take(maxPerCategory).toList()
            : items;
        if (limited.isNotEmpty) {
          final newCache = Map<int, List<Product>>.from(state.categoryCache);
          newCache[id] = limited;
          state = state.copyWith(categoryCache: newCache);
          _prefetchImages(limited);
        }
      } catch (_) {
        // Silent prefetch failure
      }
    }
  }

  void _prefetchImages(List<Product> items) {
    if (kIsWeb) {
      return;
    }
    final urls = items
        .map((p) => p.image)
        .where((u) => u != null && u.startsWith('http'))
        .cast<String>()
        .toList();
    Future(() async {
      final cm = AppCacheManager.instance;
      var count = 0;
      for (final url in urls) {
        if (count >= 120) break;
        try {
          await cm.getSingleFile(url);
          count++;
        } catch (_) {}
      }
    });
  }

  Future<void> _loadProductsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final catId = state.activeCategoryId;
      final key =
          catId != null ? 'cached_products_cat_$catId' : 'cached_products_all';
      final cached = prefs.getString(key);
      if (cached != null && cached.isNotEmpty) {
        final list = _decodeProducts(cached);
        state = state.copyWith(products: list);
      }
    } catch (_) {}
  }

  String _encodeProducts(List<Product> products) {
    return jsonEncode(products.map((p) => p.toJson()).toList());
  }

  List<Product> _decodeProducts(String data) {
    try {
      final decoded = jsonDecode(data);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}

final productProvider = StateNotifierProvider<ProductNotifier, ProductState>(
    (ref) => ProductNotifier());
