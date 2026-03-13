import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../cards/dark_info_card.dart';

/// Weather block: location, temperature, condition, date, humidity, precipitation, wind.
class WeatherDisplay extends StatelessWidget {
  const WeatherDisplay({
    super.key,
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

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DarkInfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, size: 18, color: c.textOnDark),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  location,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$temperatureCelsius°C',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.cloud_outlined, size: 20, color: c.textOnDark.withValues(alpha: 0.9)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            condition,
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateTime,
                      style: TextStyle(
                        fontSize: 12,
                        color: c.textOnDark.withValues(alpha: 0.8),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (humidityPercent != null || precipitationMm != null || windSpeedKmh != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (humidityPercent != null) _MetricChip(label: 'Humidity $humidityPercent%', c: c),
                if (precipitationMm != null) _MetricChip(label: 'Precipitation ${precipitationMm!.toInt()} mm', c: c),
                if (windSpeedKmh != null) _MetricChip(label: 'Wind Speed $windSpeedKmh km/h', c: c),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.c});

  final String label;
  final AppColorSet c;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.textOnDark.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: c.textOnDark)),
    );
  }
}
