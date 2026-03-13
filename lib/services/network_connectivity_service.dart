import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Detects if the device has data network connectivity (online/offline).
/// Use for future conditions: e.g. show cached data when offline, fetch fresh when online.
class NetworkConnectivityService {
  NetworkConnectivityService._();
  static final NetworkConnectivityService _instance = NetworkConnectivityService._();
  factory NetworkConnectivityService() => _instance;

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true;

  bool get isOnline => _isOnline;

  /// Initialize and start listening to connectivity changes.
  void startListening(void Function(bool isOnline) onChanged) {
    _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final online = _hasDataConnection(results);
      if (_isOnline != online) {
        _isOnline = online;
        onChanged(online);
      }
    });
    _checkInitial(onChanged);
  }

  /// One-time check of current connectivity.
  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = _hasDataConnection(results);
    return _isOnline;
  }

  Future<void> _checkInitial(void Function(bool) onChanged) async {
    try {
      final results = await _connectivity.checkConnectivity();
      _isOnline = _hasDataConnection(results);
      onChanged(_isOnline);
    } catch (e) {
      debugPrint('[NetworkConnectivity] Check failed: $e');
    }
  }

  bool _hasDataConnection(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
