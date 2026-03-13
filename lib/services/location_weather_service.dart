import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

import '../models/weather_model.dart';
import '../models/weather_forecast_model.dart';

/// Result of fetching real-time weather (success or error message).
sealed class WeatherResult {
  const WeatherResult();
}

class WeatherSuccess extends WeatherResult {
  const WeatherSuccess(this.weather);
  final WeatherModel weather;
}

class WeatherError extends WeatherResult {
  const WeatherError(this.message);
  final String message;
}

/// Location permission status for UI.
enum LocationPermissionStatus {
  notDetermined,
  denied,
  deniedForever,
  granted,
  serviceDisabled,
  error,
}

/// Fetches real-time location, reverse geocoding, and weather (Open-Meteo).
class LocationWeatherService {
  static const String _weatherBase = 'https://api.open-meteo.com/v1/forecast';

  /// Checks current location permission status.
  static Future<LocationPermissionStatus> checkPermissionStatus() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return LocationPermissionStatus.serviceDisabled;

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        return LocationPermissionStatus.denied;
      }
      if (permission == LocationPermission.deniedForever) {
        return LocationPermissionStatus.deniedForever;
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        return LocationPermissionStatus.granted;
      }
      return LocationPermissionStatus.notDetermined;
    } catch (_) {
      return LocationPermissionStatus.error;
    }
  }

  /// Requests location permission. Call when user taps "Allow" or when entering home.
  static Future<LocationPermissionStatus> requestPermission() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return LocationPermissionStatus.serviceDisabled;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return LocationPermissionStatus.deniedForever;
      }
      if (permission == LocationPermission.denied) {
        return LocationPermissionStatus.denied;
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        return LocationPermissionStatus.granted;
      }
      return LocationPermissionStatus.notDetermined;
    } catch (_) {
      return LocationPermissionStatus.error;
    }
  }

  /// Opens app settings so user can grant permission if denied forever.
  static Future<bool> openAppSettings() => Geolocator.openAppSettings();

  /// Returns current device position (lat, lng) or null if permission denied / error.
  static Future<({double lat, double lng})?> getCurrentPosition() async {
    try {
      final status = await checkPermissionStatus();
      if (status != LocationPermissionStatus.granted) return null;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      return (lat: position.latitude, lng: position.longitude);
    } catch (_) {
      return null;
    }
  }

  /// Fetches real-time weather for the device location. Requires permission granted.
  static Future<WeatherResult> fetchRealtimeWeather() async {
    try {
      final status = await checkPermissionStatus();
      if (status != LocationPermissionStatus.granted) {
        return WeatherError(_messageForStatus(status));
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      final placeName = await _reverseGeocode(position.latitude, position.longitude);
      final weather = await _fetchWeatherFromApi(
        position.latitude,
        position.longitude,
        placeName,
      );
      return WeatherSuccess(weather);
    } on LocationServiceDisabledException {
      return const WeatherError('Location service is disabled. Enable it in settings.');
    } on PermissionDeniedException {
      return const WeatherError('Location permission denied.');
    } catch (e) {
      return WeatherError('Failed to get weather: ${e.toString()}');
    }
  }

  /// Fetches 7-day weather forecast for the device location. Requires permission granted.
  static Future<WeatherForecastResult> fetchForecast() async {
    try {
      final status = await checkPermissionStatus();
      if (status != LocationPermissionStatus.granted) {
        return WeatherForecastError(_messageForStatus(status));
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      final placeName = await _reverseGeocode(position.latitude, position.longitude);
      final forecast = await _fetchForecastFromApi(
        position.latitude,
        position.longitude,
        placeName,
      );
      return WeatherForecastSuccess(forecast);
    } on LocationServiceDisabledException {
      return const WeatherForecastError('Location service is disabled. Enable it in settings.');
    } on PermissionDeniedException {
      return const WeatherForecastError('Location permission denied.');
    } catch (e) {
      return WeatherForecastError('Failed to get forecast: ${e.toString()}');
    }
  }

  static String _messageForStatus(LocationPermissionStatus status) {
    switch (status) {
      case LocationPermissionStatus.notDetermined:
      case LocationPermissionStatus.denied:
        return 'Location permission is required for real-time weather.';
      case LocationPermissionStatus.deniedForever:
        return 'Location was permanently denied. Open settings to allow.';
      case LocationPermissionStatus.serviceDisabled:
        return 'Please enable location services.';
      case LocationPermissionStatus.error:
        return 'Could not check permission.';
      case LocationPermissionStatus.granted:
        return '';
    }
  }

  static Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return 'Unknown';
      final p = placemarks.first;
      final parts = [
        if (p.locality != null && p.locality!.isNotEmpty) p.locality,
        if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) p.administrativeArea,
        if (p.country != null && p.country!.isNotEmpty) p.country,
      ].whereType<String>().toList();
      return parts.isEmpty ? 'Unknown' : parts.join(', ');
    } catch (_) {
      return 'Unknown';
    }
  }

  static Future<WeatherModel> _fetchWeatherFromApi(
    double lat,
    double lng,
    String locationName,
  ) async {
    final uri = Uri.parse(_weatherBase).replace(
      queryParameters: {
        'latitude': lat.toString(),
        'longitude': lng.toString(),
        'current': 'temperature_2m,relative_humidity_2m,precipitation,weather_code,wind_speed_10m',
      },
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Weather API error: ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final current = json['current'] as Map<String, dynamic>? ?? {};
    final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 0.0;
    final humidity = (current['relative_humidity_2m'] as num?)?.toInt() ?? 0;
    final precipitation = (current['precipitation'] as num?)?.toDouble() ?? 0.0;
    final windSpeed = (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0;
    final weatherCode = (current['weather_code'] as num?)?.toInt() ?? 0;

    final now = DateTime.now();
    final dateTimeStr = _formatDateTime(now);
    final condition = _weatherCodeToCondition(weatherCode);

    return WeatherModel(
      location: locationName,
      temperatureCelsius: temp.round(),
      condition: condition,
      dateTime: dateTimeStr,
      humidityPercent: humidity,
      precipitationMm: precipitation,
      windSpeedKmh: windSpeed.round(),
    );
  }

  static String _formatDateTime(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final month = months[dt.month - 1];
    final h = dt.hour;
    final m = dt.minute;
    final time = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    return '$month ${dt.day}, ${dt.year} | $time';
  }

  static String _weatherCodeToCondition(int code) {
    if (code == 0) return 'Clear';
    if (code == 1) return 'Mainly clear';
    if (code == 2) return 'Partly cloudy';
    if (code == 3) return 'Cloudy';
    if ([45, 48].contains(code)) return 'Foggy';
    if ([51, 53, 55].contains(code)) return 'Drizzle';
    if ([61, 63, 65].contains(code)) return 'Rain';
    if ([66, 67].contains(code)) return 'Freezing rain';
    if ([71, 73, 75].contains(code)) return 'Snow';
    if ([80, 81, 82].contains(code)) return 'Showers';
    if ([85, 86].contains(code)) return 'Snow showers';
    if (code == 95) return 'Thunderstorm';
    if ([96, 99].contains(code)) return 'Thunderstorm with hail';
    return 'Partly cloudy';
  }

  static Future<WeatherForecast> _fetchForecastFromApi(
    double lat,
    double lng,
    String locationName,
  ) async {
    final uri = Uri.parse(_weatherBase).replace(
      queryParameters: {
        'latitude': lat.toString(),
        'longitude': lng.toString(),
        'daily': 'temperature_2m_max,temperature_2m_min,precipitation_sum,weather_code',
        'forecast_days': '7',
      },
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Forecast API error: ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final daily = json['daily'] as Map<String, dynamic>? ?? {};
    final dates = (daily['time'] as List<dynamic>?)?.cast<String>() ?? [];
    final maxTemps = (daily['temperature_2m_max'] as List<dynamic>?) ?? [];
    final minTemps = (daily['temperature_2m_min'] as List<dynamic>?) ?? [];
    final precip = (daily['precipitation_sum'] as List<dynamic>?) ?? [];
    final codes = (daily['weather_code'] as List<dynamic>?) ?? [];

    final days = <WeatherForecastDay>[];
    for (var i = 0; i < dates.length && i < 7; i++) {
      final dateStr = dates[i];
      DateTime date;
      try {
        date = DateTime.parse(dateStr);
      } catch (_) {
        date = DateTime.now().add(Duration(days: i));
      }
      final maxT = (maxTemps.length > i ? maxTemps[i] : 0) as num?;
      final minT = (minTemps.length > i ? minTemps[i] : 0) as num?;
      final p = (precip.length > i ? precip[i] : 0.0) as num?;
      final code = (codes.length > i ? codes[i] : 0) as num?;
      days.add(WeatherForecastDay(
        date: date,
        temperatureMaxC: maxT?.round() ?? 0,
        temperatureMinC: minT?.round() ?? 0,
        condition: _weatherCodeToCondition(code?.toInt() ?? 0),
        precipitationMm: p?.toDouble() ?? 0.0,
        weatherCode: code?.toInt(),
      ));
    }
    return WeatherForecast(location: locationName, days: days);
  }
}

sealed class WeatherForecastResult {
  const WeatherForecastResult();
}

class WeatherForecastSuccess extends WeatherForecastResult {
  const WeatherForecastSuccess(this.forecast);
  final WeatherForecast forecast;
}

class WeatherForecastError extends WeatherForecastResult {
  const WeatherForecastError(this.message);
  final String message;
}
