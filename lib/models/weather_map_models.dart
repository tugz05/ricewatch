/// RainViewer radar frame for precipitation overlay.
class RainViewerFrame {
  const RainViewerFrame({required this.time, required this.path});
  final int time;
  final String path;
}

/// City marker with coordinates, temperature, and wind.
class CityWeatherMarker {
  const CityWeatherMarker({
    required this.name,
    required this.lat,
    required this.lng,
    required this.tempC,
    this.windSpeedKmh = 0,
    this.windDirectionDeg = 0,
  });
  final String name;
  final double lat;
  final double lng;
  final int tempC;
  final double windSpeedKmh;
  final int windDirectionDeg;
}
