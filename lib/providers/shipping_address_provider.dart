import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stynext/models/shipping_address.dart';
import 'package:stynext/core/api/api_service.dart';
import 'package:stynext/core/api/api_constants.dart';

class ShippingAddressState {
  final List<ShippingAddress> addresses;
  final bool isLoading;
  const ShippingAddressState(
      {this.addresses = const [], this.isLoading = false});
  ShippingAddressState copyWith(
          {List<ShippingAddress>? addresses, bool? isLoading}) =>
      ShippingAddressState(
          addresses: addresses ?? this.addresses,
          isLoading: isLoading ?? this.isLoading);
}

class ShippingAddressNotifier extends StateNotifier<ShippingAddressState> {
  ShippingAddressNotifier() : super(const ShippingAddressState());

  Future<void> fetchAddresses() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await ApiService.I.get(ApiConstants.shippingAddresses);
      if (res is List) {
        final list = res
            .map((json) => ShippingAddress.fromJson(
                Map<String, dynamic>.from(json as Map)))
            .toList();
        state = state.copyWith(addresses: list, isLoading: false);
      } else if (res is Map && res['data'] is List) {
        final list = (res['data'] as List)
            .map((json) => ShippingAddress.fromJson(
                Map<String, dynamic>.from(json as Map)))
            .toList();
        state = state.copyWith(addresses: list, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<ShippingAddress?> addAddress(Map<String, dynamic> payload) async {
    try {
      final data = Map<String, dynamic>.from(payload);
      data['name'] = (data['name'] ?? '').toString().trim();
      data['address'] = (data['address'] ?? '').toString().trim();
      data['city'] = (data['city'] ?? '').toString().trim();
      final phone = (data['phone'] ?? '').toString().trim();
      if (phone.isEmpty) {
        data.remove('phone');
      } else {
        data['phone'] = phone;
      }
      final res =
          await ApiService.I.post(ApiConstants.shippingAddresses, data);
      if (res is Map<String, dynamic>) {
        final json = res['data'] is Map ? res['data'] : res;
        final addr =
            ShippingAddress.fromJson(Map<String, dynamic>.from(json as Map));
        state = state.copyWith(addresses: [...state.addresses, addr]);
        return addr;
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  Future<ShippingAddress?> updateAddress(
      int id, Map<String, dynamic> payload) async {
    try {
      final path = '${ApiConstants.shippingAddresses}/$id';
      final data = Map<String, dynamic>.from(payload);
      data['name'] = (data['name'] ?? '').toString().trim();
      data['address'] = (data['address'] ?? '').toString().trim();
      data['city'] = (data['city'] ?? '').toString().trim();
      final phone = (data['phone'] ?? '').toString().trim();
      if (phone.isEmpty) {
        data.remove('phone');
      } else {
        data['phone'] = phone;
      }
      final res = await ApiService.I.put(path, data);
      if (res is Map<String, dynamic>) {
        final json = res['data'] is Map ? res['data'] : res;
        final addr =
            ShippingAddress.fromJson(Map<String, dynamic>.from(json as Map));
        final updated = [...state.addresses];
        final idx = updated.indexWhere((a) => a.id == id);
        if (idx != -1) {
          updated[idx] = addr;
          state = state.copyWith(addresses: updated);
        }
        return addr;
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  Future<bool> deleteAddress(int id) async {
    try {
      final path = '${ApiConstants.shippingAddresses}/$id';
      await ApiService.I.delete(path);
      state = state.copyWith(
          addresses: state.addresses.where((a) => a.id != id).toList());
      return true;
    } catch (_) {
      return false;
    }
  }
}

final shippingAddressProvider =
    StateNotifierProvider<ShippingAddressNotifier, ShippingAddressState>(
        (ref) => ShippingAddressNotifier());
