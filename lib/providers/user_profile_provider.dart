import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stynext/models/user_model.dart';
import 'package:stynext/core/di/service_locator.dart';
import 'package:stynext/domain/usecases/usecases.dart';

class UserProfileState {
  final bool loading;
  final UserModel? user;
  final String? error;
  const UserProfileState({
    this.loading = false,
    this.user,
    this.error,
  });
  UserProfileState copyWith({
    bool? loading,
    UserModel? user,
    String? error,
  }) {
    return UserProfileState(
      loading: loading ?? this.loading,
      user: user ?? this.user,
      error: error,
    );
  }
}

class UserProfileNotifier extends StateNotifier<UserProfileState> {
  final FetchUserUseCase _fetch = getIt<FetchUserUseCase>();
  final UpdateUserProfileUseCase _update = getIt<UpdateUserProfileUseCase>();
  UserProfileNotifier() : super(const UserProfileState());

  Future<void> getCurrentUser() async {
    state = state.copyWith(loading: true, error: null);
    final res = await _fetch.call();
    res.fold(
      onSuccess: (data) {
        final user = data is UserModel
            ? data
            : data is Map<String, dynamic>
                ? UserModel.fromJson(data)
                : null;
        state = state.copyWith(loading: false, user: user);
      },
      onFailure: (e) {
        state = state.copyWith(loading: false, error: e.toString());
      },
    );
  }

  Future<void> updateProfile({String? name, String? phone}) async {
    state = state.copyWith(loading: true, error: null);
    final res = await _update.call(name: name, phone: phone);
    res.fold(
      onSuccess: (data) {
        final user = data is UserModel
            ? data
            : data is Map<String, dynamic>
                ? UserModel.fromJson(data)
                : state.user;
        state = state.copyWith(loading: false, user: user);
      },
      onFailure: (e) {
        state = state.copyWith(loading: false, error: e.toString());
      },
    );
  }
}

final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfileState>(
    (ref) => UserProfileNotifier());
