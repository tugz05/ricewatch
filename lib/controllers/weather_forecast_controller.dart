import 'package:flutter/foundation.dart';
import '../models/weather_forecast_model.dart';
import '../services/location_weather_service.dart';

/// Controller for the Weather Forecast screen: loads 7-day forecast, respects online/offline.
class WeatherForecastController extends ChangeNotifier {
  WeatherForecast? _forecast;
  bool _loading = false;
  String? _error;

  WeatherForecast? get forecast => _forecast;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadForecast({required bool isOnline}) async {
    if (!isOnline) {
      _error = 'Walay koneksyon. I-on ang data o Wi-Fi aron makakuha og forecast.';
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    final result = await LocationWeatherService.fetchForecast();

    _loading = false;
    switch (result) {
      case WeatherForecastSuccess():
        _forecast = result.forecast;
        _error = null;
      case WeatherForecastError():
        _error = result.message;
        _forecast = null;
    }
    notifyListeners();
  }

  Future<void> refresh({required bool isOnline}) => loadForecast(isOnline: isOnline);
}
