import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../controllers/navigation_controller.dart';
import '../../services/network_connectivity_service.dart';
import '../../views/scan/rice_leaf_scan_view.dart';

/// Floating bottom navigation bar: Home, Weather, AI Assistant, Scan and Analyze (center), Settings.
/// History is in the app bar (top).
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const int homeIndex = 0;
  static const int weatherIndex = 1;
  static const int aiAssistantIndex = 2;
  static const int addImageIndex = 3; // center
  static const int settingsIndex = 4;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = 20.0 + (Responsive.width(context) > Responsive.breakpointTablet ? 8.0 : 0);
    final maxW = Responsive.width(context) > Responsive.breakpointDesktop ? Responsive.maxContentWidth + 40 : null;
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 24),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW ?? double.infinity),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                color: context.colors.navBar,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: context.colors.navBar.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: _NavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    selected: currentIndex == homeIndex,
                    onTap: () => onTap(homeIndex),
                  )),
                  Expanded(child: _NavItem(
                    icon: Icons.wb_sunny_rounded,
                    label: 'Weather',
                    selected: currentIndex == weatherIndex,
                    onTap: () => onTap(weatherIndex),
                  )),
                  Expanded(child: _NavItem(
                    icon: Icons.document_scanner_rounded,
                    label: 'Scan and Analyze',
                    selected: currentIndex == addImageIndex,
                    onTap: () => onTap(addImageIndex),
                    isCenter: true,
                  )),
                  Expanded(child: _NavItem(
                    icon: Icons.assistant_rounded,
                    label: 'AI Assistant',
                    selected: currentIndex == aiAssistantIndex,
                    onTap: () => onTap(aiAssistantIndex),
                  )),
                  Expanded(child: _NavItem(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    selected: currentIndex == settingsIndex,
                    onTap: () => onTap(settingsIndex),
                  )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.isCenter = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isCenter;

  @override
  Widget build(BuildContext context) {
    if (isCenter) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: context.colors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: context.colors.textPrimary.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? context.colors.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: selected
                    ? context.colors.primary
                    : context.colors.textPrimary.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: selected
                        ? context.colors.primary
                        : context.colors.textPrimary.withValues(alpha: 0.6),
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wraps AppBottomNavBar with NavigationController (for use in Home or AI Assistant).
class AppBottomNavBarWrapper extends StatelessWidget {
  const AppBottomNavBarWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationController>(
      builder: (context, nav, _) {
        return AppBottomNavBar(
          currentIndex: nav.bottomNavIndex,
          onTap: (index) async {
            if (index == AppBottomNavBar.addImageIndex) {
              // Option 1: online OpenAI-powered analyzer when connected.
              final hasNet = await NetworkConnectivityService().checkConnectivity();
              if (hasNet) {
                if (context.mounted) {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const RiceLeafScanView(autoLaunchCamera: true),
                    ),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Walay internet connection. Local offline model para sa rice leaf analysis kay i-dugang pa sa sunod na update.',
                      ),
                    ),
                  );
                }
              }
              return;
            }
            nav.setBottomNavIndex(index);
          },
        );
      },
    );
  }
}
