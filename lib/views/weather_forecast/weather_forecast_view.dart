import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../components/widgets/shimmer_loading.dart';
import '../../core/utils/responsive.dart';
import '../../controllers/weather_forecast_controller.dart';
import '../../controllers/weather_map_controller.dart';
import '../../controllers/network_connectivity_controller.dart';
import '../../models/weather_forecast_model.dart';
import '../../components/navigation/app_bottom_nav_bar.dart';
import '../../components/app_bar/history_app_bar_button.dart';
import 'weather_map_view.dart';

/// Weather Forecast screen: 7-day forecast + interactive map (Windy-style).
class WeatherForecastView extends StatefulWidget {
  const WeatherForecastView({super.key});

  @override
  State<WeatherForecastView> createState() => _WeatherForecastViewState();
}

class _WeatherForecastViewState extends State<WeatherForecastView> {
  bool _showMap = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadIfNeeded());
  }

  void _loadIfNeeded() {
    final forecast = context.read<WeatherForecastController>();
    final mapCtrl = context.read<WeatherMapController>();
    final connectivity = context.read<NetworkConnectivityController>();
    final online = connectivity.isOnline;

    // Kick off both loads in parallel so GPS is fetched once for each.
    if (forecast.forecast == null && !forecast.loading) {
      forecast.loadForecast(isOnline: online);
    }
    // Pre-fetch user location for the map even before the map tab is opened,
    // so Windy opens instantly on the user's position when they switch tabs.
    if (!mapCtrl.locationLoaded && !mapCtrl.loading) {
      mapCtrl.load(isOnline: online);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, c),
            Expanded(
              child: _showMap
                  ? const _WeatherMapSection()
                  : _buildBody(context, c),
            ),
            const AppBottomNavBarWrapper(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColorSet c) {
    return Consumer2<NetworkConnectivityController, WeatherForecastController>(
      builder: (context, connectivity, forecast, _) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.horizontalPadding(context),
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: c.header,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: c.accentLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.wb_sunny_rounded, color: c.textPrimary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Weather Forecast',
                      style: TextStyle(
                        color: c.textOnDark,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const HistoryAppBarButton(),
                  _NetworkStatusChip(isOnline: connectivity.isOnline, c: c),
                ],
              ),
              if (forecast.forecast != null && !_showMap) ...[
                const SizedBox(height: 8),
                Text(
                  forecast.forecast!.location,
                  style: TextStyle(
                    color: c.textOnDark.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
              const SizedBox(height: 12),
              _SegmentBar(
                showMap: _showMap,
                onChanged: (v) => setState(() => _showMap = v),
                c: c,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AppColorSet c) {
    return Consumer2<NetworkConnectivityController, WeatherForecastController>(
      builder: (context, connectivity, forecast, _) {
        if (forecast.loading) {
          return _ForecastLoadingBody(c: c);
        }

        if (forecast.error != null) {
          return _buildError(context, forecast.error!, connectivity.isOnline, forecast, c);
        }

        if (forecast.forecast == null || forecast.forecast!.days.isEmpty) {
          return _buildEmpty(context, connectivity.isOnline, forecast, c);
        }

        return RefreshIndicator(
          color: c.primary,
          onRefresh: () => forecast.refresh(isOnline: connectivity.isOnline),
          child: ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.horizontalPadding(context),
              vertical: 16,
            ),
            itemCount: forecast.forecast!.days.length,
            itemBuilder: (context, index) {
              final day = forecast.forecast!.days[index];
              return _ForecastDayCard(day: day, c: c);
            },
          ),
        );
      },
    );
  }

  Widget _buildError(BuildContext context, String message, bool isOnline, WeatherForecastController forecast, AppColorSet c) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Responsive.horizontalPadding(context) + 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 64, color: c.textSecondary.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: c.textSecondary, height: 1.4),
            ),
            if (!isOnline) ...[
              const SizedBox(height: 16),
              Text(
                'I-on ang data o Wi-Fi aron makakuha og forecast.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: c.textMuted),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: isOnline ? () => forecast.loadForecast(isOnline: true) : null,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: c.accent,
                foregroundColor: c.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, bool isOnline, WeatherForecastController forecast, AppColorSet c) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wb_cloudy_rounded, size: 64, color: c.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'Walay forecast. Pull to refresh.',
            style: TextStyle(fontSize: 15, color: c.textSecondary),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => forecast.loadForecast(isOnline: isOnline),
            icon: Icon(Icons.refresh, color: c.primary),
            label: Text('Load forecast', style: TextStyle(color: c.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class _WeatherMapSection extends StatefulWidget {
  const _WeatherMapSection();

  @override
  State<_WeatherMapSection> createState() => _WeatherMapSectionState();
}

class _WeatherMapSectionState extends State<_WeatherMapSection> {
  @override
  Widget build(BuildContext context) {
    // Location is pre-loaded in _loadIfNeeded(); no extra trigger needed here.
    return const WeatherMapView();
  }
}

/// Shimmer skeleton matching forecast list: 6 ForecastDayCard placeholders.
class _ForecastLoadingBody extends StatelessWidget {
  const _ForecastLoadingBody({required this.c});
  final AppColorSet c;

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.horizontalPadding(context);
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return _ForecastDayCardShimmer(c: c);
      },
    );
  }
}

class _ForecastDayCardShimmer extends StatelessWidget {
  const _ForecastDayCardShimmer({required this.c});
  final AppColorSet c;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ShimmerLoading(
        baseColor: c.primaryContainer.withValues(alpha: 0.6),
        highlightColor: c.textPrimary.withValues(alpha: 0.15),
        child: Row(
          children: [
            SizedBox(
              width: 70,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 40,
                    decoration: BoxDecoration(
                      color: c.primaryContainer.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    height: 12,
                    width: 50,
                    decoration: BoxDecoration(
                      color: c.primaryContainer.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: c.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 14,
                    width: 80,
                    decoration: BoxDecoration(
                      color: c.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  height: 18,
                  width: 36,
                  decoration: BoxDecoration(
                    color: c.primaryContainer.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  height: 13,
                  width: 28,
                  decoration: BoxDecoration(
                    color: c.primaryContainer.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentBar extends StatelessWidget {
  const _SegmentBar({required this.showMap, required this.onChanged, required this.c});

  final bool showMap;
  final ValueChanged<bool> onChanged;
  final AppColorSet c;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.textOnDark.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentTab(
              label: 'Forecast',
              icon: Icons.calendar_today_rounded,
              selected: !showMap,
              onTap: () => onChanged(false),
              c: c,
            ),
          ),
          Expanded(
            child: _SegmentTab(
              label: 'Map',
              icon: Icons.map_rounded,
              selected: showMap,
              onTap: () => onChanged(true),
              c: c,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  const _SegmentTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.c,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final AppColorSet c;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? c.accent.withValues(alpha: 0.9) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? c.onPrimary : c.textOnDark.withValues(alpha: 0.8)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? c.onPrimary : c.textOnDark.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NetworkStatusChip extends StatelessWidget {
  const _NetworkStatusChip({required this.isOnline, required this.c});

  final bool isOnline;
  final AppColorSet c;

  @override
  Widget build(BuildContext context) {
    final statusColor = isOnline ? c.success : c.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnline ? Icons.wifi : Icons.wifi_off_rounded,
            size: 16,
            color: statusColor,
          ),
          const SizedBox(width: 6),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ForecastDayCard extends StatelessWidget {
  const _ForecastDayCard({required this.day, required this.c});

  final WeatherForecastDay day;
  final AppColorSet c;

  static const List<String> _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final weekday = _weekdays[day.date.weekday - 1];
    final dateStr = '${_months[day.date.month - 1]} ${day.date.day}';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weekday,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 12,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _iconForCondition(day.condition),
                  size: 28,
                  color: c.accent.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 12),
                Text(
                  day.condition,
                  style: TextStyle(
                    fontSize: 14,
                    color: c.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${day.temperatureMaxC}°',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              Text(
                '${day.temperatureMinC}°',
                style: TextStyle(
                  fontSize: 13,
                  color: c.textSecondary,
                ),
              ),
              if (day.precipitationMm > 0)
                Text(
                  '${day.precipitationMm.toStringAsFixed(1)} mm',
                  style: TextStyle(
                    fontSize: 11,
                    color: c.textMuted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconForCondition(String condition) {
    if (condition.contains('Clear')) return Icons.wb_sunny_rounded;
    if (condition.contains('Cloud') || condition.contains('Fog')) return Icons.cloud_rounded;
    if (condition.contains('Rain') || condition.contains('Drizzle') || condition.contains('Shower')) {
      return Icons.water_drop_rounded;
    }
    if (condition.contains('Thunder')) return Icons.thunderstorm_rounded;
    if (condition.contains('Snow')) return Icons.ac_unit_rounded;
    return Icons.cloud_outlined;
  }
}
