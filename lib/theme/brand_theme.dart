import 'package:flutter/material.dart';

import 'brand_config.dart';
import 'brand_tokens.dart';

/// Builds Material themes from local WhiteLabel configuration.
abstract final class BrandTheme {
  static ThemeData light(BrandConfig config) =>
      _build(config, Brightness.light);

  static ThemeData dark(BrandConfig config) => _build(config, Brightness.dark);

  static ThemeData _build(BrandConfig config, Brightness brightness) {
    final palette = brightness == Brightness.light ? config.light : config.dark;
    final tokens = BrandTokens(
      bg: palette.bg,
      surface: palette.surface,
      surfaceAlt: palette.surfaceAlt,
      primary: palette.primary,
      onPrimary: palette.onPrimary,
      secondary: palette.secondary,
      onSecondary: palette.onSecondary,
      text: palette.text,
      textMuted: palette.textMuted,
      border: palette.border,
      success: palette.success,
      warning: palette.warning,
      danger: palette.danger,
      headFont: config.headFont,
      bodyFont: config.bodyFont,
      radiusSm: config.radii.sm,
      radiusMd: config.radii.md,
      radiusLg: config.radii.lg,
    );
    final textTheme = TextTheme(
      displayLarge: _text(config.headFont, 34, FontWeight.w700, palette.text),
      displayMedium: _text(config.headFont, 28, FontWeight.w700, palette.text),
      titleLarge: _text(config.headFont, 20, FontWeight.w700, palette.text),
      titleMedium: _text(config.bodyFont, 17, FontWeight.w600, palette.text),
      bodyLarge: _text(config.bodyFont, 15, FontWeight.w400, palette.text),
      bodyMedium: _text(config.bodyFont, 15, FontWeight.w400, palette.text),
      labelLarge: _text(config.bodyFont, 13, FontWeight.w700, palette.text),
      labelMedium:
          _text(config.bodyFont, 13, FontWeight.w600, palette.textMuted),
      labelSmall:
          _text(config.bodyFont, 11, FontWeight.w600, palette.textMuted),
    );
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: palette.primary,
      onPrimary: palette.onPrimary,
      secondary: palette.secondary,
      onSecondary: palette.onSecondary,
      error: palette.danger,
      onError: palette.surface,
      surface: palette.surface,
      onSurface: palette.text,
    );
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(config.radii.md),
      side: BorderSide(color: palette.border),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.bg,
      cardColor: palette.surface,
      dividerColor: palette.border,
      textTheme: textTheme,
      extensions: [tokens],
      appBarTheme: AppBarTheme(
        backgroundColor: palette.primary,
        foregroundColor: palette.onPrimary,
        elevation: 0,
        titleTextStyle:
            textTheme.titleLarge?.copyWith(color: palette.onPrimary),
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: cardShape,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(config.radii.md),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(config.radii.md),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(config.radii.md),
          borderSide: BorderSide(color: palette.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(44, 44),
          backgroundColor: palette.primary,
          foregroundColor: palette.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(config.radii.sm),
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        modalBarrierColor: tokens.sheetBackdrop,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(config.radii.lg),
          ),
        ),
      ),
    );
  }

  static TextStyle _text(
    String family,
    double size,
    FontWeight weight,
    Color color,
  ) =>
      resolveBrandFont(family).copyWith(
        fontSize: size,
        fontWeight: weight,
        color: color,
      );
}
