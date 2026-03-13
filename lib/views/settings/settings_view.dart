import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/navigation/app_bottom_nav_bar.dart';
import '../../controllers/theme_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/asset_paths.dart';
import '../../core/utils/responsive.dart';
import '../../views/scan/scan_history_view.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final padding = Responsive.horizontalPadding(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(c: c),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(padding, 16, padding, 24),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Responsive.constrainMaxWidth(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  _SectionTitle('Appearance', c: c),
                  _ThemeTile(c: c),
                  const SizedBox(height: 20),
                  _SectionTitle('Features', c: c),
                  _FeatureTile(
                    icon: Icons.history_rounded,
                    title: 'Scan History',
                    subtitle: 'View all rice leaf disease scan records',
                    c: c,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const ScanHistoryView()),
                    ),
                  ),
                  _FeatureTile(
                    icon: Icons.document_scanner_rounded,
                    title: 'Scan & Analyze',
                    subtitle: 'Identify rice leaf diseases using AI camera',
                    c: c,
                    badge: 'AI',
                    onTap: () {},
                  ),
                  _FeatureTile(
                    icon: Icons.wb_sunny_rounded,
                    title: 'Weather Forecast',
                    subtitle: 'Real-time weather and forecast for your field',
                    c: c,
                    onTap: () {},
                  ),
                  _FeatureTile(
                    icon: Icons.smart_toy_rounded,
                    title: 'AI Assistant',
                    subtitle: 'Rice farming advice in Cebuano/Bisaya',
                    c: c,
                    badge: 'AI',
                    onTap: () {},
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle('Notifications', c: c),
                  _SwitchTile(
                    icon: Icons.notifications_rounded,
                    title: 'Disease Alerts',
                    subtitle: 'Get notified when risk is detected in your area',
                    c: c,
                    value: true,
                    onChanged: (_) {},
                  ),
                  _SwitchTile(
                    icon: Icons.water_drop_rounded,
                    title: 'Weather Alerts',
                    subtitle: 'Rain, drought and temperature warnings',
                    c: c,
                    value: true,
                    onChanged: (_) {},
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle('Data & Privacy', c: c),
                  _FeatureTile(
                    icon: Icons.delete_sweep_rounded,
                    title: 'Clear Scan History',
                    subtitle: 'Delete all saved scan records',
                    c: c,
                    destructive: true,
                    onTap: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: c.card,
                          title: Text('Clear all scan history?',
                              style: TextStyle(
                                  color: c.textPrimary,
                                  fontWeight: FontWeight.w700)),
                          content: Text(
                              'This will permanently delete all scan records.',
                              style: TextStyle(color: c.textSecondary)),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: Text('Cancel',
                                    style: TextStyle(color: c.textMuted))),
                            TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: Text('Delete',
                                    style: TextStyle(color: c.error))),
                          ],
                        ),
                      );
                      if (ok == true && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Scan history cleared.')),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle('About', c: c),
                  _FeatureTile(
                    icon: Icons.info_outline_rounded,
                    title: 'About RiceWatch',
                    subtitle: 'Version 1.0.0 · AI-powered rice farming assistant',
                    c: c,
                    onTap: () => _showAbout(context, c),
                  ),
                    ],
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

  void _showAbout(BuildContext context, AppColorSet c) {
    showAboutDialog(
      context: context,
      applicationName: 'RiceWatch',
      applicationVersion: '1.0.0',
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(AssetPaths.logo, width: 56, height: 56,
            errorBuilder: (_, _, _) =>
                Icon(Icons.grass_rounded, size: 56, color: c.primary)),
      ),
      children: [
        Text(
          'RiceWatch is an AI-powered rice farming assistant for Filipino farmers. '
          'It provides real-time weather data, rice leaf disease detection using '
          'computer vision, and a Cebuano-speaking AI assistant for practical '
          'farming advice.',
          style: TextStyle(color: c.textSecondary, height: 1.5),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.c});
  final AppColorSet c;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: c.header,
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(AssetPaths.logo,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Icon(Icons.grass_rounded, size: 44, color: c.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Settings',
                    style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                Text('Customize your experience',
                    style:
                        TextStyle(color: c.textMuted, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {required this.c});
  final String title;
  final AppColorSet c;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: c.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({required this.c});
  final AppColorSet c;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ThemeController>();
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.divider),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: c.accentLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.palette_rounded, color: c.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Theme Mode',
                        style: TextStyle(
                            color: c.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                    Text('Choose light, dark or system default',
                        style:
                            TextStyle(color: c.textMuted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _ThemeOption(
                icon: Icons.light_mode_rounded,
                label: 'Light',
                selected: ctrl.mode == ThemeMode.light,
                c: c,
                onTap: () => ctrl.setMode(ThemeMode.light),
              ),
              const SizedBox(width: 8),
              _ThemeOption(
                icon: Icons.dark_mode_rounded,
                label: 'Dark',
                selected: ctrl.mode == ThemeMode.dark,
                c: c,
                onTap: () => ctrl.setMode(ThemeMode.dark),
              ),
              const SizedBox(width: 8),
              _ThemeOption(
                icon: Icons.brightness_auto_rounded,
                label: 'System',
                selected: ctrl.mode == ThemeMode.system,
                c: c,
                onTap: () => ctrl.setMode(ThemeMode.system),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.c,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final AppColorSet c;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? c.primary : c.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? c.primary : c.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 20,
                  color: selected ? c.onPrimary : c.textMuted),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? c.onPrimary : c.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.c,
    required this.onTap,
    this.badge,
    this.destructive = false,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final AppColorSet c;
  final VoidCallback onTap;
  final String? badge;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final tileColor = destructive ? c.error : c.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.divider),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: tileColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: tileColor, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      color: destructive ? c.error : c.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(badge!,
                    style: TextStyle(
                        color: c.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
        subtitle: Text(subtitle,
            style: TextStyle(color: c.textMuted, fontSize: 12)),
        trailing: Icon(Icons.chevron_right_rounded,
            color: c.textMuted, size: 20),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.c,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final AppColorSet c;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.divider),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: c.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: c.primary, size: 20),
        ),
        title: Text(title,
            style: TextStyle(
                color: c.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15)),
        subtitle: Text(subtitle,
            style: TextStyle(color: c.textMuted, fontSize: 12)),
        trailing: Switch(value: value, onChanged: onChanged),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      ),
    );
  }
}
