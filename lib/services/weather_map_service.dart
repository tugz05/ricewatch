import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_map_models.dart';

/// RainViewer API + Open-Meteo for weather map data.
/// All city weather is fetched in a SINGLE batch request for performance.
class WeatherMapService {
  static const String _rainViewerApi = 'https://api.rainviewer.com/public/weather-maps.json';
  static const String _openMeteoBase = 'https://api.open-meteo.com/v1/forecast';

  /// Key Philippine cities: 8 spread across the archipelago.
  static const List<({String name, double lat, double lng})> _phCities = [
    (name: 'Manila',         lat: 14.5995, lng: 120.9842),
    (name: 'Cebu City',      lat: 10.3157, lng: 123.8854),
    (name: 'Davao',          lat:  7.0731, lng: 125.6128),
    (name: 'Baguio',         lat: 16.4023, lng: 120.5960),
    (name: 'Cagayan de Oro', lat:  8.4542, lng: 124.6319),
    (name: 'Zamboanga',      lat:  6.9214, lng: 122.0790),
    (name: 'Legazpi',        lat: 13.1391, lng: 123.7442),
    (name: 'Tuguegarao',     lat: 17.6134, lng: 121.7269),
  ];

  /// Fetches RainViewer radar frames.
  static Future<({List<RainViewerFrame> frames, String host})> fetchRainViewerFrames() async {
    const defaultHost = 'https://tilecache.rainviewer.com';
    try {
      final response = await http.get(Uri.parse(_rainViewerApi)).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout'),
      );
      if (response.statusCode != 200) return (frames: <RainViewerFrame>[], host: defaultHost);
      final json = jsonDecode(response.body) as Map<String, dynamic>?;
      if (json == null) return (frames: <RainViewerFrame>[], host: defaultHost);
      final host = (json['host'] as String?) ?? defaultHost;
      final past = (json['radar']?['past'] as List<dynamic>?) ?? [];
      final frames = past.map((e) {
        final m = e as Map<String, dynamic>;
        return RainViewerFrame(
          time: m['time'] as int? ?? 0,
          path: m['path'] as String? ?? '',
        );
      }).toList();
      return (frames: frames, host: host);
    } catch (_) {
      return (frames: <RainViewerFrame>[], host: defaultHost);
    }
  }

  /// Tile URL template for a RainViewer frame.
  static String tileUrlTemplate(String host, String path) {
    final base = host.endsWith('/') ? host : '$host/';
    final p = path.startsWith('/') ? path.substring(1) : path;
    return '$base$p/256/{z}/{x}/{y}/2/1_1.png';
  }

  /// Fetches weather for all predefined cities in ONE batch HTTP request.
  /// Returns an empty list on error rather than throwing.
  static Future<List<CityWeatherMarker>> fetchCityTemps() async {
    try {
      final lats = _phCities.map((c) => c.lat.toString()).join(',');
      final lngs = _phCities.map((c) => c.lng.toString()).join(',');
      final uri = Uri.parse(_openMeteoBase).replace(queryParameters: {
        'latitude': lats,
        'longitude': lngs,
        'current': 'temperature_2m,wind_speed_10m,wind_direction_10m',
        'timeformat': 'unixtime',
      });
      final response = await http.get(uri).timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw Exception('Timeout'),
      );
      if (response.statusCode != 200) return [];
      final body = jsonDecode(response.body);

      // Open-Meteo returns a list when multiple lat/lng are given.
      final List<dynamic> results = body is List ? body : [body];
      final markers = <CityWeatherMarker>[];
      for (var i = 0; i < results.length && i < _phCities.length; i++) {
        final city = _phCities[i];
        final current = (results[i] as Map<String, dynamic>?)?['current']
            as Map<String, dynamic>? ?? {};
        final temp = (current['temperature_2m'] as num?)?.toDouble();
        if (temp == null) continue;
        markers.add(CityWeatherMarker(
          name: city.name,
          lat: city.lat,
          lng: city.lng,
          tempC: temp.round(),
          windSpeedKmh: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0,
          windDirectionDeg: (current['wind_direction_10m'] as num?)?.toInt() ?? 0,
        ));
      }
      return markers;
    } catch (_) {
      return [];
    }
  }

  /// Fetches weather for a single location (user's GPS position).
  static Future<CityWeatherMarker?> fetchWeatherAt(
    double lat,
    double lng, {
    String name = 'You',
  }) async {
    try {
      final uri = Uri.parse(_openMeteoBase).replace(queryParameters: {
        'latitude': lat.toString(),
        'longitude': lng.toString(),
        'current': 'temperature_2m,wind_speed_10m,wind_direction_10m',
        'timeformat': 'unixtime',
      });
      final response = await http.get(uri).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Timeout'),
      );
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>?;
      final current = json?['current'] as Map<String, dynamic>? ?? {};
      final temp = (current['temperature_2m'] as num?)?.toDouble();
      if (temp == null) return null;
      return CityWeatherMarker(
        name: name,
        lat: lat,
        lng: lng,
        tempC: temp.round(),
        windSpeedKmh: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0,
        windDirectionDeg: (current['wind_direction_10m'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return null;
    }
  }
}
