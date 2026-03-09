import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:stynext/core/api/api_service.dart';
import 'package:stynext/models/category.dart';
import 'package:stynext/core/cache/app_cache_manager.dart';
import 'package:stynext/core/di/service_locator.dart';
import 'package:stynext/domain/usecases/usecases.dart';
import 'package:stynext/core/cache/cache_service.dart';

class CategoryState {
  final List<Category> categories;
  final bool isLoading;
  final String? errorMessage;
  const CategoryState({
    this.categories = const [],
    this.isLoading = false,
    this.errorMessage,
  });
  CategoryState copyWith({
    List<Category>? categories,
    bool? isLoading,
    String? errorMessage,
  }) =>
      CategoryState(
        categories: categories ?? this.categories,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
      );
}

class CategoryNotifier extends StateNotifier<CategoryState> {
  final ApiService _api = ApiService.I;
  final FetchCategoriesUseCase _fetchCategories =
      getIt<FetchCategoriesUseCase>();
  final FetchProductsByCategoryUseCase _fetchProductsByCategory =
      getIt<FetchProductsByCategoryUseCase>();
  CategoryNotifier() : super(const CategoryState());

  Future<Map<String, dynamic>> fetchCategoryWithProducts(
    int categoryId, {
    int limit = 100,
  }) async {
    final data = await _api.getCategoryWithProducts(categoryId, limit: limit);
    return data;
  }

  Future<void> fetchCategories() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _fetchCategories.call();
      result.fold(
        onSuccess: (list) async {
          state = state.copyWith(categories: list, isLoading: false);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'cached_categories',
            jsonEncode(list.map((c) => c.toJson()).toList()),
          );
          await CacheService.init();
          await CacheService.putCategories(
            list.map((c) => c.toJson()).toList(),
          );
          _prefetchImages(list);
        },
        onFailure: (error) async {
          await _loadFromCache();
          await CacheService.init();
          final maps = CacheService.getCategories();
          if (maps.isNotEmpty) {
            final cats = maps
                .map((e) => Category.fromJson(Map<String, dynamic>.from(e)))
                .toList();
            state = state.copyWith(categories: cats);
          }
          state =
              state.copyWith(isLoading: false, errorMessage: error.toString());
        },
      );
    } catch (_) {
      await _loadFromCache();
      await CacheService.init();
      final maps = CacheService.getCategories();
      if (maps.isNotEmpty) {
        final cats = maps
            .map((e) => Category.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        state = state.copyWith(categories: cats);
      }
      state = state.copyWith(
          isLoading: false, errorMessage: 'An unexpected error occurred');
    }
  }

  Future<List<dynamic>> getCategoryProducts(String categoryId) async {
    try {
      final result = await _fetchProductsByCategory.call(categoryId);
      return result.getOrNull() ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_categories');
      if (cached != null && cached.isNotEmpty) {
        final list = jsonDecode(cached);
        if (list is List) {
          final cats = list
              .map((e) => Category.fromJson(e as Map<String, dynamic>))
              .toList();
          state = state.copyWith(categories: cats);
        }
      }
    } catch (_) {}
  }

  void _prefetchImages(List<Category> cats) {
    final urls = cats
        .map((c) => c.image)
        .where((u) => u != null && u.startsWith('http'))
        .cast<String>()
        .toList();
    Future(() async {
      final cm = AppCacheManager.instance;
      var count = 0;
      for (final url in urls) {
        if (count >= 90) break;
        try {
          await cm.getSingleFile(url);
          count++;
        } catch (_) {}
      }
    });
  }
}

final categoryProvider = StateNotifierProvider<CategoryNotifier, CategoryState>(
    (ref) => CategoryNotifier());
