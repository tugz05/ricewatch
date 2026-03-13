import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_weather_service.dart';

/// Lightweight controller for the weather map.
/// Only manages user GPS location and loading state.
/// All weather visualization is delegated to the Windy embed.
class WeatherMapController extends ChangeNotifier {
  LatLng? _userLocation;
  bool _loading = false;
  String? _error;
  bool _locationLoaded = false;

  LatLng? get userLocation => _userLocation;
  bool get loading => _loading;
  String? get error => _error;
  bool get locationLoaded => _locationLoaded;

  Future<void> load({required bool isOnline}) async {
    if (_locationLoaded) return;
    if (!isOnline) {
      _error = 'Walay koneksyon. I-on ang data o Wi-Fi.';
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final pos = await LocationWeatherService.getCurrentPosition();
      _userLocation = pos != null ? LatLng(pos.lat, pos.lng) : null;
      _locationLoaded = true;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
