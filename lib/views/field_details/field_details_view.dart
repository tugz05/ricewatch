import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../controllers/field_detail_controller.dart';
import '../../models/field_model.dart';
import '../../components/cards/dark_info_card.dart';
import '../../components/widgets/sensor_stats_grid.dart';
import '../../components/widgets/crop_pill_button.dart';

/// Field detail screen: header, background, stats overlay, crop pill, sensor grid.
class FieldDetailsView extends StatelessWidget {
  const FieldDetailsView({super.key});

  static FieldModel _defaultField() => const FieldModel(
        id: '1',
        name: 'My Garden field',
        totalAreaHectares: 12,
        plantAgeDays: 45,
        yieldTons: 15,
        waterDepthPercent: 35,
        plantHealthPercent: 56,
        soilQualityPercent: 75,
        pestRiskPercent: 10,
      );

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FieldDetailController()..setField(_defaultField()),
      child: const _FieldDetailsBody(),
    );
  }
}

class _FieldDetailsBody extends StatelessWidget {
  const _FieldDetailsBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackground(context),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final pad = Responsive.horizontalPadding(context);
                      return Stack(
                        children: [
                          const SizedBox.expand(),
                          Positioned(
                            top: 16,
                            right: pad,
                            child: _buildStatsOverlay(context),
                          ),
                          Positioned(
                            left: pad,
                            top: 24,
                            right: pad,
                            child: _buildCropPill(context),
                          ),
                          Positioned(
                            left: pad,
                            right: pad,
                            bottom: 24,
                            child: _buildSensorCard(context),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryLight.withValues(alpha: 0.3),
            AppColors.surfaceLight,
          ],
        ),
      ),
      child: CustomPaint(
        painter: _FieldTerrainPainter(),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer<FieldDetailController>(
      builder: (context, ctrl, _) {
        final field = ctrl.field ?? FieldDetailsView._defaultField();
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.horizontalPadding(context),
            vertical: 12,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surfaceLight,
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
              ),
              Expanded(
                child: Text(
                  field.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryLight,
                child: Icon(Icons.person, color: AppColors.textPrimary, size: 20),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsOverlay(BuildContext context) {
    return Consumer<FieldDetailController>(
      builder: (context, ctrl, _) {
        final field = ctrl.field;
        if (field == null) return const SizedBox.shrink();
        return DarkInfoCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total Area ${field.totalAreaHectares?.toInt() ?? 0} Hectares',
                  style: const TextStyle(fontSize: 13)),
              if (field.plantAgeDays != null)
                Text('Plant Age ${field.plantAgeDays} Days', style: const TextStyle(fontSize: 13)),
              if (field.yieldTons != null)
                Text('Yield ${field.yieldTons?.toInt() ?? 0} Tons', style: const TextStyle(fontSize: 13)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCropPill(BuildContext context) {
    return Consumer<FieldDetailController>(
      builder: (context, ctrl, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < ctrl.crops.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CropPillButton(
                    label: ctrl.crops[i],
                    icon: const Icon(Icons.eco, size: 18, color: AppColors.primary),
                    selected: ctrl.selectedCropIndex == i,
                    onTap: () => ctrl.setSelectedCrop(i),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSensorCard(BuildContext context) {
    return Consumer<FieldDetailController>(
      builder: (context, ctrl, _) {
        final field = ctrl.field;
        if (field == null) return const SizedBox.shrink();
        return SensorStatsGrid(
          waterDepthPercent: field.waterDepthPercent ?? 0,
          plantHealthPercent: field.plantHealthPercent ?? 0,
          soilQualityPercent: field.soilQualityPercent ?? 0,
          pestRiskPercent: field.pestRiskPercent ?? 0,
        );
      },
    );
  }
}

class _FieldTerrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryLight.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(size.width * 0.2, size.height * 0.25, size.width * 0.5, size.height * 0.28);
    path.quadraticBezierTo(size.width * 0.8, size.height * 0.3, size.width, size.height * 0.27);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
