import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stynext/models/payment_method.dart';
import 'package:stynext/core/api/api_service.dart';
import 'package:stynext/core/api/api_constants.dart';

class PaymentMethodProvider extends ChangeNotifier {
  List<PaymentMethod> _methods = [];
  bool _isLoading = false;

  List<PaymentMethod> get methods => [..._methods];
  bool get isLoading => _isLoading;

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  Future<void> fetchMethods() async {
    _setLoading(true);
    try {
      final res = await ApiService.I.get(ApiConstants.paymentMethods);
      final data = res.data is Map ? res.data['data'] : res.data;
      if (data is List) {
        _methods = data.map((json) => PaymentMethod.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching payment methods: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<PaymentMethod?> addMethod(Map<String, dynamic> payload) async {
    try {
      final res = await ApiService.I.post(ApiConstants.paymentMethods, payload);
      final json = res.data is Map ? (res.data['data'] ?? res.data) : res.data;
      if (json is Map<String, dynamic>) {
        final method = PaymentMethod.fromJson(json);
        _methods.add(method);
        notifyListeners();
        return method;
      }
    } catch (e) {
      debugPrint('Error adding payment method: $e');
    }
    return null;
  }

  Future<bool> removeMethod(int id) async {
    try {
      final path = '${ApiConstants.paymentMethods}/$id';
      await ApiService.I.delete(path);
      _methods.removeWhere((m) => m.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error removing payment method: $e');
      return false;
    }
  }
}

final paymentMethodProvider =
    ChangeNotifierProvider<PaymentMethodProvider>(
        (ref) => PaymentMethodProvider());
