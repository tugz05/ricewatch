import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/cards/field_content_card.dart';
import '../../components/cards/dark_info_card.dart';
import '../../components/navigation/app_bottom_nav_bar.dart';
import '../../components/app_bar/history_app_bar_button.dart';
import '../../components/widgets/weather_display.dart';
import '../../components/widgets/shimmer_loading.dart';
import '../../components/buttons/filter_chip_button.dart';
import '../../controllers/navigation_controller.dart';
import '../../controllers/home_controller.dart';
import '../../core/constants/asset_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/scan_record_model.dart';
import '../../services/location_weather_service.dart';
import '../../services/scan_database_service.dart';
import '../field_details/field_details_view.dart';
import '../scan/rice_leaf_scan_view.dart';
import '../scan/scan_history_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  List<ScanRecord> _recentScans = [];

  @override
  void initState() {
    super.initState();
    _loadRecentScans();
  }

  Future<void> _loadRecentScans() async {
    final all = await ScanDatabaseService.getAll();
    if (!mounted) return;
    setState(() => _recentScans = all.take(3).toList());
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
              child: RefreshIndicator(
                color: c.primary,
                onRefresh: () async {
                  await context.read<HomeController>().refreshWeather();
                  await _loadRecentScans();
                },
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    Responsive.horizontalPadding(context), 16,
                    Responsive.horizontalPadding(context), 16,
                  ),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Responsive.constrainMaxWidth(
                    context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWeather(context, c),
                        const SizedBox(height: 20),
                        _buildQuickActions(context, c),
                        const SizedBox(height: 20),
                        _buildRecentScans(context, c),
                        const SizedBox(height: 20),
                        _buildMyFields(context, c),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const AppBottomNavBarWrapper(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColorSet c) {
    final padding = Responsive.horizontalPadding(context);
    return Consumer<HomeController>(
      builder: (context, home, _) => Container(
        padding: EdgeInsets.fromLTRB(padding + 4, 16, padding + 4, 20),
        decoration: BoxDecoration(
          color: c.header,
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                AssetPaths.logo,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => CircleAvatar(
                  radius: 24,
                  backgroundColor: c.accentLight,
                  child: Text(
                    home.user.displayName.isNotEmpty
                        ? home.user.displayName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: c.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, ${home.user.displayName}',
                    style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    'Monitor your rice fields',
                    style: TextStyle(color: c.textMuted, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const HistoryAppBarButton(),
            Stack(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.notifications_outlined,
                      color: c.textPrimary),
                ),
                if (home.hasUnreadNotifications)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: c.error, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeather(BuildContext context, AppColorSet c) {
    return Consumer<HomeController>(
      builder: (context, home, _) {
        if (home.weatherLoading) return _WeatherLoadingCard(c: c);
        if (home.weatherError != null) {
          return _WeatherErrorCard(
            message: home.weatherError!,
            permissionStatus: home.permissionStatus,
            onAllow: home.requestLocationPermission,
            onOpenSettings: home.openLocationSettings,
            onRetry: home.refreshWeather,
            c: c,
          );
        }
        final w = home.weather;
        return WeatherDisplay(
          location: w.location,
          temperatureCelsius: w.temperatureCelsius,
          condition: w.condition,
          dateTime: w.dateTime,
          humidityPercent: w.humidityPercent,
          precipitationMm: w.precipitationMm,
          windSpeedKmh: w.windSpeedKmh,
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context, AppColorSet c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: c.textPrimary)),
        const SizedBox(height: 12),
        Row(
          children: [
            _QuickAction(
              icon: Icons.document_scanner_rounded,
              label: 'Scan Leaf',
              color: c.primary,
              bgColor: c.accentLight,
              c: c,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) =>
                        const RiceLeafScanView(autoLaunchCamera: true)),
              ),
            ),
            const SizedBox(width: 10),
            _QuickAction(
              icon: Icons.smart_toy_rounded,
              label: 'AI Chat',
              color: const Color(0xFF5C6BC0),
              bgColor: const Color(0xFFE8EAF6),
              c: c,
              onTap: () => context
                  .read<NavigationController>()
                  .setBottomNavIndex(AppBottomNavBar.aiAssistantIndex),
            ),
            const SizedBox(width: 10),
            _QuickAction(
              icon: Icons.wb_sunny_rounded,
              label: 'Weather',
              color: const Color(0xFFF57C00),
              bgColor: const Color(0xFFFFF3E0),
              c: c,
              onTap: () => context
                  .read<NavigationController>()
                  .setBottomNavIndex(AppBottomNavBar.weatherIndex),
            ),
            const SizedBox(width: 10),
            _QuickAction(
              icon: Icons.history_rounded,
              label: 'History',
              color: const Color(0xFF00897B),
              bgColor: const Color(0xFFE0F2F1),
              c: c,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const ScanHistoryView()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentScans(BuildContext context, AppColorSet c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Scans',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: c.textPrimary)),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const ScanHistoryView()),
              ),
              child:
                  Text('See All', style: TextStyle(color: c.primary)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_recentScans.isEmpty)
          _EmptyScansBanner(c: c, onScan: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (_) =>
                    const RiceLeafScanView(autoLaunchCamera: true)));
          })
        else
          Column(
            children: _recentScans
                .map((r) => _RecentScanTile(record: r, c: c))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildMyFields(BuildContext context, AppColorSet c) {
    final nav = context.read<NavigationController>();
    return Consumer<HomeController>(
      builder: (context, home, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('My Rice Fields',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: c.textPrimary)),
              TextButton(
                onPressed: () {},
                child:
                    Text('See All', style: TextStyle(color: c.primary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < home.categories.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChipButton(
                      label: home.categories[i],
                      selected: home.selectedCategoryIndex == i,
                      onTap: () => home.setSelectedCategory(i),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final isTablet = Responsive.isTabletOrLarger(context);
            if (isTablet) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 220,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: home.fieldContents.length,
                itemBuilder: (context, index) {
                  final item = home.fieldContents[index];
                  return FieldContentCard(
                    title: item.title,
                    description: item.description,
                    imageWidget: _placeholderImage(c),
                    isBookmarked: item.isBookmarked,
                    onBookmarkTap: () => home.toggleBookmark(item.id),
                    onTap: () {
                      nav.selectField(item.fieldId);
                      _goToFieldDetails(context);
                    },
                  );
                },
              );
            }
            return SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: home.fieldContents.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = home.fieldContents[index];
                  return SizedBox(
                    width: 260,
                    child: FieldContentCard(
                      title: item.title,
                      description: item.description,
                      imageWidget: _placeholderImage(c),
                      isBookmarked: item.isBookmarked,
                      onBookmarkTap: () =>
                          home.toggleBookmark(item.id),
                      onTap: () {
                        nav.selectField(item.fieldId);
                        _goToFieldDetails(context);
                      },
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _placeholderImage(AppColorSet c) => Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: c.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
            child: Icon(Icons.grass, size: 48, color: c.primary)),
      );

  void _goToFieldDetails(BuildContext context) {
    Navigator.of(context).push(
        MaterialPageRoute<void>(
            builder: (context) => const FieldDetailsView()));
  }
}

// ── Quick Action Button ───────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.c,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final AppColorSet c;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? color.withValues(alpha: 0.18) : bgColor;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: color.withValues(alpha: isDark ? 0.3 : 0.15)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Recent Scan Tile ──────────────────────────────────────────────────────────

class _RecentScanTile extends StatelessWidget {
  const _RecentScanTile({required this.record, required this.c});
  final ScanRecord record;
  final AppColorSet c;

  @override
  Widget build(BuildContext context) {
    final top = record.diseases.isNotEmpty ? record.diseases.first : null;
    final color = top?.riskColor ?? c.accent;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.divider),
      ),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 48,
            height: 48,
            child: _thumb(),
          ),
        ),
        title: Text(
          record.topDisease,
          style: TextStyle(
              color: c.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: top != null
            ? Text(
                top.percentage > 0
                    ? '${top.percentageLabel} · ${top.riskLabel}'
                    : top.riskLabel,
                style: TextStyle(color: color, fontSize: 12),
              )
            : Text(_formatDate(record.createdAt),
                style: TextStyle(color: c.textMuted, fontSize: 12)),
        trailing: Text(_formatDate(record.createdAt),
            style: TextStyle(color: c.textMuted, fontSize: 11)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }

  Widget _thumb() {
    if (record.imagePath.isEmpty || kIsWeb) {
      return Container(
        color: const Color(0xFF1A2E1D),
        child: const Icon(Icons.image_rounded, color: Colors.white24, size: 20),
      );
    }
    final f = File(record.imagePath);
    if (!f.existsSync()) {
      return Container(
        color: const Color(0xFF1A2E1D),
        child: const Icon(Icons.broken_image_rounded,
            color: Colors.white24, size: 20),
      );
    }
    return Image.file(f, fit: BoxFit.cover);
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.month}/${dt.day}';
  }
}

// ── Empty Scans Banner ────────────────────────────────────────────────────────

class _EmptyScansBanner extends StatelessWidget {
  const _EmptyScansBanner({required this.c, required this.onScan});
  final AppColorSet c;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onScan,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: c.accentLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.document_scanner_rounded,
                  color: c.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No scans yet',
                      style: TextStyle(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  Text('Tap to scan your first rice leaf',
                      style:
                          TextStyle(color: c.textMuted, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: c.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Weather Loading/Error ─────────────────────────────────────────────────────

class _WeatherLoadingCard extends StatelessWidget {
  const _WeatherLoadingCard({required this.c});
  final AppColorSet c;

  @override
  Widget build(BuildContext context) {
    return DarkInfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            _Shimmer(width: 18, height: 18, c: c),
            const SizedBox(width: 6),
            Expanded(child: _Shimmer(height: 14, width: 140, c: c)),
          ]),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _Shimmer(height: 32, width: 64, c: c),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    _Shimmer(width: 20, height: 20, c: c),
                    const SizedBox(width: 6),
                    Expanded(child: _Shimmer(height: 14, width: 80, c: c)),
                  ]),
                  const SizedBox(height: 4),
                  _Shimmer(height: 12, width: 120, c: c),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _Shimmer(height: 28, width: 90, c: c),
            _Shimmer(height: 28, width: 110, c: c),
            _Shimmer(height: 28, width: 100, c: c),
          ]),
        ],
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  const _Shimmer({required this.width, required this.height, required this.c});
  final double width;
  final double height;
  final AppColorSet c;

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      baseColor: Colors.white.withValues(alpha: 0.35),
      highlightColor: Colors.white.withValues(alpha: 0.75),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class _WeatherErrorCard extends StatelessWidget {
  const _WeatherErrorCard({
    required this.message,
    required this.permissionStatus,
    required this.onAllow,
    required this.onOpenSettings,
    required this.onRetry,
    required this.c,
  });

  final String message;
  final LocationPermissionStatus permissionStatus;
  final VoidCallback onAllow;
  final VoidCallback onOpenSettings;
  final VoidCallback onRetry;
  final AppColorSet c;

  @override
  Widget build(BuildContext context) {
    final isPermissionDenied =
        permissionStatus == LocationPermissionStatus.denied ||
            permissionStatus == LocationPermissionStatus.notDetermined;
    final isDeniedForever =
        permissionStatus == LocationPermissionStatus.deniedForever;

    return DarkInfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Icon(Icons.location_off, size: 18, color: c.textPrimary),
            const SizedBox(width: 6),
            const Text('Location & weather',
                style: TextStyle(fontSize: 14)),
          ]),
          const SizedBox(height: 10),
          Text(message,
              style: TextStyle(fontSize: 13, color: c.textPrimary),
              maxLines: 5,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (isPermissionDenied)
              FilledButton.icon(
                onPressed: onAllow,
                icon: const Icon(Icons.location_on, size: 18),
                label: const Text('Allow location'),
                style: FilledButton.styleFrom(
                  backgroundColor: c.accentLight,
                  foregroundColor: c.textPrimary,
                ),
              ),
            if (isDeniedForever)
              OutlinedButton.icon(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings, size: 18),
                label: const Text('Open settings'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: c.textPrimary,
                  side: BorderSide(color: c.textPrimary),
                ),
              ),
            TextButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh, size: 18, color: c.textPrimary),
              label: Text('Retry',
                  style: TextStyle(color: c.textPrimary)),
            ),
          ]),
        ],
      ),
    );
  }
}
