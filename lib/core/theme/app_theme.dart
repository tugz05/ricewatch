import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(AppColorSet.light, Brightness.light);
  static ThemeData get dark  => _build(AppColorSet.dark,  Brightness.dark);

  static ThemeData _build(AppColorSet c, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary:          c.primary,
        onPrimary:        c.onPrimary,
        primaryContainer: c.primaryContainer,
        onPrimaryContainer: c.textPrimary,
        secondary:        c.accent,
        onSecondary:      c.onPrimary,
        secondaryContainer: c.accentLight,
        onSecondaryContainer: c.textPrimary,
        surface:          c.surface,
        onSurface:        c.textPrimary,
        error:            c.error,
        onError:          Colors.white,
        surfaceContainerHighest: c.surfaceVariant,
        outline:          c.divider,
      ),
      scaffoldBackgroundColor: c.background,
      cardColor:               c.card,
      dividerColor:            c.divider,
      appBarTheme: AppBarTheme(
        backgroundColor: c.header,
        foregroundColor: c.textPrimary,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: c.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        iconTheme: IconThemeData(color: c.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: c.card,
        elevation: brightness == Brightness.dark ? 0 : 2,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.textPrimary,
          side: BorderSide(color: c.divider),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.accent,
        titleTextStyle: TextStyle(
          color: c.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: TextStyle(color: c.textMuted, fontSize: 13),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.primary : c.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? c.primary.withValues(alpha: 0.4)
              : c.divider,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: c.textMuted),
      ),
    );
  }
}
