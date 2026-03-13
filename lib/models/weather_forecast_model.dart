/// Single day in a weather forecast.
class WeatherForecastDay {
  const WeatherForecastDay({
    required this.date,
    required this.temperatureMaxC,
    required this.temperatureMinC,
    required this.condition,
    required this.precipitationMm,
    this.weatherCode,
  });

  final DateTime date;
  final int temperatureMaxC;
  final int temperatureMinC;
  final String condition;
  final double precipitationMm;
  final int? weatherCode;
}

/// Weather forecast result: location + list of daily forecasts.
class WeatherForecast {
  const WeatherForecast({
    required this.location,
    required this.days,
  });

  final String location;
  final List<WeatherForecastDay> days;
}
