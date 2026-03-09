import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stynext/core/api/api_service.dart';
import 'package:stynext/models/review.dart';

class ReviewState {
  final Map<int, List<Review>> cache;
  final Map<int, bool> loading;
  final Map<int, String?> error;
  const ReviewState({
    this.cache = const {},
    this.loading = const {},
    this.error = const {},
  });
  ReviewState copyWith({
    Map<int, List<Review>>? cache,
    Map<int, bool>? loading,
    Map<int, String?>? error,
  }) =>
      ReviewState(
        cache: cache ?? this.cache,
        loading: loading ?? this.loading,
        error: error ?? this.error,
      );
}

class ReviewNotifier extends StateNotifier<ReviewState> {
  ReviewNotifier() : super(const ReviewState());
  final _api = ApiService.I;

  List<Review> reviewsFor(int productId) => state.cache[productId] ?? const [];
  bool isLoading(int productId) => state.loading[productId] ?? false;
  String? errorFor(int productId) => state.error[productId];

  Future<void> fetch(int productId) async {
    state = state.copyWith(
      loading: {...state.loading, productId: true},
      error: {...state.error, productId: null},
    );
    try {
      final data = await _api.get('/products/$productId/reviews');
      List<Review> list = [];
      if (data is List) {
        list = data
            .map((e) => Review.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (data is Map && data['data'] is List) {
        list = (data['data'] as List)
            .map((e) => Review.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      state = state.copyWith(
        cache: {...state.cache, productId: list},
      );
    } catch (e) {
      state = state.copyWith(error: {...state.error, productId: e.toString()});
    } finally {
      state =
          state.copyWith(loading: {...state.loading, productId: false});
    }
  }

  Future<void> submit(int productId, String comment, int rating) async {
    await _api.post('/products/$productId/reviews', {
      'comment': comment,
      'rating': rating,
    });
    await fetch(productId);
  }
}

final reviewProvider =
    StateNotifierProvider<ReviewNotifier, ReviewState>((ref) => ReviewNotifier());
