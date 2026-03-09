import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stynext/models/product.dart';
import 'package:stynext/core/di/service_locator.dart';
import 'package:stynext/domain/usecases/usecases.dart';

class SearchState {
  final bool loading;
  final String query;
  final List<Product> results;
  final String? error;
  const SearchState({
    this.loading = false,
    this.query = '',
    this.results = const [],
    this.error,
  });
  SearchState copyWith({
    bool? loading,
    String? query,
    List<Product>? results,
    String? error,
  }) {
    return SearchState(
      loading: loading ?? this.loading,
      query: query ?? this.query,
      results: results ?? this.results,
      error: error,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  final FetchProductsUseCase _fetchProducts = getIt<FetchProductsUseCase>();
  Timer? _debounce;
  SearchNotifier() : super(const SearchState());

  void setQuery(String q) {
    state = state.copyWith(query: q);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _search(q);
    });
  }

  Future<void> _search(String q) async {
    if (q.isEmpty) {
      state = state.copyWith(results: [], error: null, loading: false);
      return;
    }
    state = state.copyWith(loading: true, error: null);
    final res = await _fetchProducts.call(search: q, page: 1, perPage: 50);
    res.fold(
      onSuccess: (items) {
        state = state.copyWith(loading: false, results: items, error: null);
      },
      onFailure: (e) {
        state = state.copyWith(loading: false, error: e.toString());
      },
    );
  }
}

final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) => SearchNotifier());
