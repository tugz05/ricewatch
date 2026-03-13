/// Weather data for location/field.
class WeatherModel {
  const WeatherModel({
    required this.location,
    required this.temperatureCelsius,
    required this.condition,
    required this.dateTime,
    this.humidityPercent,
    this.precipitationMm,
    this.windSpeedKmh,
  });

  final String location;
  final int temperatureCelsius;
  final String condition;
  final String dateTime;
  final int? humidityPercent;
  final double? precipitationMm;
  final int? windSpeedKmh;
}
