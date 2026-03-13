import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../components/widgets/shimmer_loading.dart';
import '../../controllers/weather_map_controller.dart';
import 'windy_embed.dart';

/// Philippines geographic centre (fallback when GPS is unavailable).
const double _phLat = 12.8797;
const double _phLng = 121.7740;

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer skeleton shown while location / page is loading.
// ─────────────────────────────────────────────────────────────────────────────
class _MapLoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Stack(
      fit: StackFit.expand,
      children: [
        ShimmerLoading(
          baseColor: c.primaryContainer.withValues(alpha: 0.6),
          highlightColor: c.textPrimary.withValues(alpha: 0.15),
          child: Container(color: c.primaryContainer.withValues(alpha: 0.7)),
        ),
        Positioned(
          top: 12, left: 12, right: 12,
          child: ShimmerLoading(
            baseColor: c.primaryContainer.withValues(alpha: 0.6),
            highlightColor: c.textPrimary.withValues(alpha: 0.15),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: c.primaryContainer.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        Center(
          child: Text(
            'Loading map…',
            style: TextStyle(color: c.textSecondary, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Available Windy overlay layers.
// ─────────────────────────────────────────────────────────────────────────────
const _overlays = [
  (id: 'wind',     label: 'Wind',     icon: Icons.air_rounded),
  (id: 'temp',     label: 'Temp',     icon: Icons.thermostat_rounded),
  (id: 'rain',     label: 'Rain',     icon: Icons.water_drop_rounded),
  (id: 'clouds',   label: 'Clouds',   icon: Icons.cloud_rounded),
  (id: 'pressure', label: 'Pressure', icon: Icons.speed_rounded),
];

// ─────────────────────────────────────────────────────────────────────────────
// Main weather map view — embeds the real Windy.com map.
// On Flutter Web  : native <iframe> via HtmlElementView (no webview APIs).
// On Android/iOS  : webview_flutter WebViewWidget.
// ─────────────────────────────────────────────────────────────────────────────
class WeatherMapView extends StatefulWidget {
  const WeatherMapView({super.key});

  @override
  State<WeatherMapView> createState() => _WeatherMapViewState();
}

class _WeatherMapViewState extends State<WeatherMapView> {
  String _overlay = 'wind';

  /// Windy embed URL with all layers, centered on [lat]/[lng].
  String _buildUrl(double lat, double lng, String overlay) =>
      'https://embed.windy.com/embed2.html'
      '?lat=${lat.toStringAsFixed(4)}'
      '&lon=${lng.toStringAsFixed(4)}'
      '&detailLat=${lat.toStringAsFixed(4)}'
      '&detailLon=${lng.toStringAsFixed(4)}'
      '&zoom=7'
      '&level=surface'
      '&overlay=$overlay'
      '&product=ecmwf'
      '&menu='
      '&message=true'
      '&marker=true'
      '&calendar=now'
      '&pressure='
      '&type=map'
      '&location=coordinates'
      '&detail='
      '&metricWind=km%2Fh'
      '&metricTemp=%C2%B0C'
      '&radarRange=-1';

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherMapController>(
      builder: (context, ctrl, _) {
        // ── Wait for GPS result before building the embed URL ────────────────
        // This guarantees Windy opens *once* at the correct location instead
        // of first loading with the Philippines fallback then reloading.
        if (ctrl.loading || !ctrl.locationLoaded) {
          return _MapLoadingSkeleton();
        }

        // Hard network error (no location and no fallback possible).
        if (ctrl.error != null && ctrl.userLocation == null) {
          final c = context.colors;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off_rounded,
                      size: 48, color: c.textMuted),
                  const SizedBox(height: 16),
                  Text(ctrl.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.textSecondary)),
                ],
              ),
            ),
          );
        }

        // Use exact GPS coordinates; fall back to PH centre only if denied.
        final lat = ctrl.userLocation?.latitude ?? _phLat;
        final lng = ctrl.userLocation?.longitude ?? _phLng;
        final hasLocation = ctrl.userLocation != null;

        final url = _buildUrl(lat, lng, _overlay);

        return Column(
          children: [
            // ── Layer selector lives OUTSIDE the iframe — zero UX conflict ──
            _LayerSelector(
              current: _overlay,
              onSelect: (id) => setState(() => _overlay = id),
            ),

            // ── "No GPS" notice ──────────────────────────────────────────────
            if (!hasLocation)
              Builder(
                builder: (context) {
                  final c = context.colors;
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    color: c.warning.withValues(alpha: 0.9),
                    child: Row(
                      children: [
                        Icon(Icons.location_off_rounded,
                            size: 14, color: c.textPrimary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Location unavailable — showing Philippines center.',
                            style: TextStyle(
                                color: c.textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

            // ── Windy embed fills all remaining vertical space ───────────────
            Expanded(child: buildWindyEmbed(url)),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overlay layer selector — bottom floating pill bar.
// Each chip meets the 48 dp minimum tap-target from Material guidelines.
// ─────────────────────────────────────────────────────────────────────────────
class _LayerSelector extends StatelessWidget {
  const _LayerSelector({required this.current, required this.onSelect});

  final String current;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      color: c.header,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: _overlays.map((o) {
          final selected = o.id == current;
          return Expanded(
            child: _LayerChip(
              icon: o.icon,
              label: o.label,
              selected: selected,
              onTap: () => onSelect(o.id),
              c: c,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LayerChip extends StatelessWidget {
  const _LayerChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.c,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final AppColorSet c;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? c.primary
              : c.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: selected
              ? null
              : Border.all(
                  color: c.textOnDark.withValues(alpha: 0.25),
                  width: 1,
                ),
        ),
        constraints: const BoxConstraints(minHeight: 52),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected
                  ? c.onPrimary
                  : c.textOnDark.withValues(alpha: 0.9),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? c.onPrimary
                    : c.textOnDark.withValues(alpha: 0.9),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
