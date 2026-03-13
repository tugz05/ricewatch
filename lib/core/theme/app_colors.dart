import 'package:flutter/material.dart';

// ── Context extension ──────────────────────────────────────────────────────

/// Usage:  final c = context.colors;
///         c.background / c.primary / c.textPrimary / etc.
extension AppColorsContext on BuildContext {
  AppColorSet get colors =>
      Theme.of(this).brightness == Brightness.dark
          ? AppColorSet.dark
          : AppColorSet.light;
}

// ── Instance color set (light + dark) ─────────────────────────────────────

class AppColorSet {
  const AppColorSet._({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.card,
    required this.navBar,
    required this.header,
    required this.primary,
    required this.primaryContainer,
    required this.accent,
    required this.accentLight,
    required this.onPrimary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textOnDark,
    required this.divider,
    required this.error,
    required this.success,
    required this.warning,
  });

  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color card;
  final Color navBar;
  final Color header;
  final Color primary;
  final Color primaryContainer;
  final Color accent;
  final Color accentLight;
  final Color onPrimary;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textOnDark;
  final Color divider;
  final Color error;
  final Color success;
  final Color warning;

  static const AppColorSet light = AppColorSet._(
    background:       Color(0xFFF5F8F4),
    surface:          Color(0xFFFFFFFF),
    surfaceVariant:   Color(0xFFEDF4EC),
    card:             Color(0xFFFFFFFF),
    navBar:           Color(0xFFE2EDE0),
    header:           Color(0xFFD4E3D2),
    primary:          Color(0xFF4A8C4E),
    primaryContainer: Color(0xFFC8E6C9),
    accent:           Color(0xFF9BB89A),
    accentLight:      Color(0xFFE8F0E7),
    onPrimary:        Color(0xFFFFFFFF),
    textPrimary:      Color(0xFF1A2E1C),
    textSecondary:    Color(0xFF3A5A3D),
    textMuted:        Color(0xFF6B8C6E),
    textOnDark:       Color(0xFF2D3B30),
    divider:          Color(0xFFDDEBDB),
    error:            Color(0xFFB00020),
    success:          Color(0xFF388E3C),
    warning:          Color(0xFFF57C00),
  );

  static const AppColorSet dark = AppColorSet._(
    background:       Color(0xFF0F1F14),
    surface:          Color(0xFF152110),
    surfaceVariant:   Color(0xFF1A2E1D),
    card:             Color(0xFF1E3322),
    navBar:           Color(0xFF152110),
    header:           Color(0xFF152110),
    primary:          Color(0xFF66BB6A),
    primaryContainer: Color(0xFF2A4A2E),
    accent:           Color(0xFF9BB89A),
    accentLight:      Color(0xFF2A3F2C),
    onPrimary:        Color(0xFF0F2012),
    textPrimary:      Color(0xFFE8F5E9),
    textSecondary:    Color(0xFFA5C8A8),
    textMuted:        Color(0xFF6B8C6E),
    textOnDark:       Color(0xFFE8F5E9),
    divider:          Color(0xFF253D27),
    error:            Color(0xFFEF5350),
    success:          Color(0xFF66BB6A),
    warning:          Color(0xFFFFB74D),
  );
}

// ── Static AppColors (legacy + new code that can't use BuildContext) ────────

/// Static color constants — light palette values used as fallback when a
/// BuildContext is not available. For context-aware theming use context.colors.
class AppColors {
  AppColors._();

  // Primary greens
  static const Color primary        = Color(0xFF4A8C4E);
  static const Color primaryDark    = Color(0xFFE2EDE0);
  static const Color primaryLight   = Color(0xFFD4E3D2);
  static const Color primaryContainer = Color(0xFFC8E6C9);

  // Accents
  static const Color accent         = Color(0xFF9BB89A);
  static const Color accentLight    = Color(0xFFE8F0E7);

  // Surfaces / backgrounds
  static const Color surfaceLight   = Color(0xFFF5F8F4);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFFE2EDE0);

  // Text
  static const Color textPrimary    = Color(0xFF1A2E1C);
  static const Color textSecondary  = Color(0xFF3A5A3D);
  static const Color textMuted      = Color(0xFF6B8C6E);
  static const Color textOnDark     = Color(0xFF2D3B30);

  // Utility
  static const Color divider        = Color(0xFFDDEBDB);
  static const Color error          = Color(0xFFB00020);
  static const Color success        = Color(0xFF388E3C);
  static const Color warning        = Color(0xFFF57C00);
}
