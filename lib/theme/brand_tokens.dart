import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Families shipped as assets in `pubspec.yaml`.
const _bundledFamilies = {
  'Myriad',
  'Flipahaus',
  'MadeTommy',
  'AmpleSoft',
  'Continumm',
  'Bossa',
  'ComicSans',
  'iCourier',
};

/// Resolves a configured family name to a usable base text style.
///
/// Bundled families are used directly. Anything else is looked up in Google
/// Fonts, which is how brands such as bmcargo get Rubik without shipping the
/// file. When runtime fetching is disabled — golden runs, or a build that
/// bundles its own copies — the family name is passed through so the platform
/// resolves it, instead of the loader throwing mid-paint.
TextStyle resolveBrandFont(String family) {
  if (_bundledFamilies.contains(family) ||
      !GoogleFonts.config.allowRuntimeFetching) {
    return TextStyle(fontFamily: family);
  }
  try {
    return GoogleFonts.getFont(family);
  } on Exception {
    return TextStyle(fontFamily: family);
  }
}

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

  /// Scrim behind modal sheets and dialogs.
  ///
  /// The prototype dims the whole frame so the panel reads as modal; the flat
  /// [sheetBackdrop] veil is reserved for non-modal overlays.
  Color get modalScrim => const Color(0xff000000).withValues(alpha: 0.4);

  /// Top stop of the gradient laid over banner artwork.
  Color get scrimTop => const Color(0xff000000).withValues(alpha: 0.05);

  /// Bottom stop of the same gradient, dark enough to carry a title.
  Color get scrimBottom => const Color(0xff000000).withValues(alpha: 0.55);

  /// Foreground over a scrim. Fixed across brands so captions stay legible
  /// whatever artwork the brand ships.
  Color get onScrim => const Color(0xffffffff);

  /// Backdrop a brand mark is placed on.
  ///
  /// Logos are authored for a light background, so this stays white in both
  /// themes rather than following `surface` and swallowing the artwork.
  Color get logoBackdrop => const Color(0xffffffff);

  /// Returns the standard timeline glow for [accent].
  Color timelineGlow(Color accent) => accent.withValues(alpha: 0.16);

  /// Wash used behind icons and soft status badges tinted with [accent].
  Color accentWash(Color accent, [double opacity = 0.12]) =>
      accent.withValues(alpha: opacity);

  /// Translucent layer painted over [primary] inside the brand header.
  Color headerOverlay(double opacity) => onPrimary.withValues(alpha: opacity);

  /// Picks whichever of [text] or [surface] reads best over [background].
  Color onAccent(Color background) {
    final overText = _contrast(background, text);
    final overSurface = _contrast(background, surface);
    return overText >= overSurface ? text : surface;
  }

  static double _contrast(Color first, Color second) {
    final a = first.computeLuminance() + 0.05;
    final b = second.computeLuminance() + 0.05;
    return a > b ? a / b : b / a;
  }

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

/// Builds text styles from the brand font families.
///
/// Screens express the sizes and weights of the design reference through these
/// helpers so no widget ever names a font family.
extension BrandTypography on BrandTokens {
  TextStyle head(
    double size, {
    FontWeight weight = FontWeight.w700,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      resolveBrandFont(headFont).copyWith(
        fontSize: size,
        fontWeight: weight,
        color: color ?? text,
        height: height,
        letterSpacing: letterSpacing,
      );

  TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      resolveBrandFont(bodyFont).copyWith(
        fontSize: size,
        fontWeight: weight,
        color: color ?? text,
        height: height,
        letterSpacing: letterSpacing,
      );

  /// Uppercase eyebrow used for section labels and table headers.
  TextStyle eyebrow(double size, {Color? color}) => body(
        size,
        weight: FontWeight.w600,
        color: color ?? textMuted,
        letterSpacing: size * 0.08,
      );
}
