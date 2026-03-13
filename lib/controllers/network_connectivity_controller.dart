import 'package:flutter/foundation.dart';
import '../services/network_connectivity_service.dart';

/// Exposes online/offline status for UI and future conditions (e.g. fetch when online, use cache when offline).
class NetworkConnectivityController extends ChangeNotifier {
  final NetworkConnectivityService _service = NetworkConnectivityService();

  bool _isOnline = true;

  bool get isOnline => _isOnline;

  void startListening() {
    _service.startListening((online) {
      _isOnline = online;
      notifyListeners();
    });
  }

  Future<bool> checkConnectivity() async {
    final online = await _service.checkConnectivity();
    if (_isOnline != online) {
      _isOnline = online;
      notifyListeners();
    }
    return online;
  }
}
