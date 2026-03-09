import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NetworkService extends StateNotifier<bool> {
  static final NetworkService _instance = NetworkService._internal();
  late Connectivity _connectivity;
  ConnectivityResult _lastResult = ConnectivityResult.none;
  bool _isOnline = false;

  factory NetworkService() {
    return _instance;
  }

  NetworkService._internal() : super(false);

  bool get isOnline => _isOnline;
  ConnectivityResult get lastResult => _lastResult;

  Future<void> initialize() async {
    _connectivity = Connectivity();
    _lastResult = await _connectivity.checkConnectivity();
    _updateStatus();

    _connectivity.onConnectivityChanged.listen((result) {
      _lastResult = result;
      _updateStatus();
      state = _isOnline;
    });
  }

  void _updateStatus() {
    _isOnline = _lastResult != ConnectivityResult.none;
  }

  Future<bool> checkConnection() async {
    _lastResult = await _connectivity.checkConnectivity();
    _updateStatus();
    return _isOnline;
  }
}

final networkProvider =
    StateNotifierProvider<NetworkService, bool>((ref) => NetworkService._instance);
