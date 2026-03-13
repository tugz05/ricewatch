import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../cards/dark_info_card.dart';

/// 2x2 grid of sensor metrics: Water Depth, Plant Health, Soil Quality, Pest Risk.
class SensorStatsGrid extends StatelessWidget {
  const SensorStatsGrid({
    super.key,
    required this.waterDepthPercent,
    required this.plantHealthPercent,
    required this.soilQualityPercent,
    required this.pestRiskPercent,
  });

  final int waterDepthPercent;
  final int plantHealthPercent;
  final int soilQualityPercent;
  final int pestRiskPercent;

  @override
  Widget build(BuildContext context) {
    return DarkInfoCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.water_drop_outlined,
                  label: 'Water Depth',
                  value: '$waterDepthPercent%',
                ),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.eco_outlined,
                  label: 'Plant Health',
                  value: '$plantHealthPercent%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.terrain_outlined,
                  label: 'Soil Quality',
                  value: '$soilQualityPercent%',
                ),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.bug_report_outlined,
                  label: 'Pest Risk',
                  value: '$pestRiskPercent%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: AppColors.textOnDark),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textOnDark.withValues(alpha: 0.9),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
