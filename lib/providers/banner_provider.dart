import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stynext/core/api/api_service.dart';
import 'package:stynext/core/api/api_constants.dart';
import 'package:stynext/models/banner_model.dart';

class BannerState {
  final List<BannerModel> banners;
  final bool isLoading;
  const BannerState({this.banners = const [], this.isLoading = false});
  BannerState copyWith({List<BannerModel>? banners, bool? isLoading}) =>
      BannerState(banners: banners ?? this.banners, isLoading: isLoading ?? this.isLoading);
}

class BannerNotifier extends StateNotifier<BannerState> {
  final ApiService _api = ApiService.I;
  BannerNotifier() : super(const BannerState());

  Future<void> fetchBanners() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _api.get(ApiConstants.banners);
      final data = res;
      List<BannerModel> parsed = [];
      if (data is Map && data['data'] is List) {
        parsed = (data['data'] as List)
            .map((e) => BannerModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (data is List) {
        parsed = data
            .map((e) => BannerModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      final home = parsed.where((b) => (b.position) == 'home').toList();
      state = state.copyWith(banners: home, isLoading: false);
    } catch (_) {
      state = state.copyWith(banners: [], isLoading: false);
    }
  }
}

final bannerProvider =
    StateNotifierProvider<BannerNotifier, BannerState>((ref) => BannerNotifier());
