import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stynext/models/help_center_info.dart';
import 'package:stynext/core/api/api_service.dart';
import 'package:stynext/core/api/api_constants.dart';

class HelpCenterProvider extends ChangeNotifier {
  HelpCenterInfo? _info;
  bool _isLoading = false;

  HelpCenterInfo? get info => _info;
  bool get isLoading => _isLoading;

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  Future<void> fetchInfo() async {
    _setLoading(true);
    try {
      final res = await ApiService.I.get(ApiConstants.helpCenter);
      final data = res.data is Map ? (res.data['data'] ?? res.data) : res.data;
      if (data is Map<String, dynamic>) {
        _info = HelpCenterInfo.fromJson(data);
      }
    } catch (e) {
      debugPrint('Error fetching help center info: $e');
    } finally {
      _setLoading(false);
    }
  }
}

final helpCenterProvider =
    ChangeNotifierProvider<HelpCenterProvider>((ref) => HelpCenterProvider());
