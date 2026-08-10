import 'package:flutter/material.dart';

/// Semantic brand values consumed by every redesigned widget.
@immutable
final class BrandTokens extends ThemeExtension<BrandTokens> {
  const BrandTokens({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.text,
    required this.textMuted,
    required this.border,
    required this.success,
    required this.warning,
    required this.danger,
    required this.headFont,
    required this.bodyFont,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
  });

  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color text;
  final Color textMuted;
  final Color border;
  final Color success;
  final Color warning;
  final Color danger;
  final String headFont;
  final String bodyFont;
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;

  /// Second header gradient stop derived from [primary].
  Color get headerGradientEnd => Color.lerp(
        primary,
        onPrimary.computeLuminance() > 0.5
            ? const Color(0xff000000)
            : const Color(0xffffffff),
        0.22,
      )!;

  /// Sheet backdrop derived from the active text color.
  Color get sheetBackdrop => text.withValues(alpha: 0.12);

  /// Returns the standard timeline glow for [accent].
  Color timelineGlow(Color accent) => accent.withValues(alpha: 0.16);

  @override
  BrandTokens copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceAlt,
    Color? primary,
    Color? onPrimary,
    Color? secondary,
    Color? onSecondary,
    Color? text,
    Color? textMuted,
    Color? border,
    Color? success,
    Color? warning,
    Color? danger,
    String? headFont,
    String? bodyFont,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
  }) =>
      BrandTokens(
        bg: bg ?? this.bg,
        surface: surface ?? this.surface,
        surfaceAlt: surfaceAlt ?? this.surfaceAlt,
        primary: primary ?? this.primary,
        onPrimary: onPrimary ?? this.onPrimary,
        secondary: secondary ?? this.secondary,
        onSecondary: onSecondary ?? this.onSecondary,
        text: text ?? this.text,
        textMuted: textMuted ?? this.textMuted,
        border: border ?? this.border,
        success: success ?? this.success,
        warning: warning ?? this.warning,
        danger: danger ?? this.danger,
        headFont: headFont ?? this.headFont,
        bodyFont: bodyFont ?? this.bodyFont,
        radiusSm: radiusSm ?? this.radiusSm,
        radiusMd: radiusMd ?? this.radiusMd,
        radiusLg: radiusLg ?? this.radiusLg,
      );

  @override
  BrandTokens lerp(BrandTokens? other, double t) {
    if (other == null) {
      return this;
    }
    return BrandTokens(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      headFont: t < 0.5 ? headFont : other.headFont,
      bodyFont: t < 0.5 ? bodyFont : other.bodyFont,
      radiusSm: radiusSm + (other.radiusSm - radiusSm) * t,
      radiusMd: radiusMd + (other.radiusMd - radiusMd) * t,
      radiusLg: radiusLg + (other.radiusLg - radiusLg) * t,
    );
  }
}

/// Provides concise access to the active semantic tokens.
extension BrandBuildContext on BuildContext {
  BrandTokens get brand => Theme.of(this).extension<BrandTokens>()!;
}
