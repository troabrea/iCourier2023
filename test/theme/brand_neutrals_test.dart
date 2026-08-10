import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icourier/theme/brand_config.dart';
import 'package:icourier/theme/brand_tokens.dart';

/// Sum of the per-channel distance between two colours.
int _distance(Color a, Color b) =>
    ((a.r - b.r).abs() * 255 +
            (a.g - b.g).abs() * 255 +
            (a.b - b.b).abs() * 255)
        .round();

Color _hex(String value) =>
    Color(int.parse('ff${value.substring(1)}', radix: 16));

void main() {
  group('neutrales derivados del matiz de marca', () {
    // The two reference identities of spec §2.2. The derived family must land
    // close enough to them that a brand declaring only its primary still reads
    // warm or cool the way the design intends.
    const korrenLight = Color(0xffC1602E);
    const verraLight = Color(0xff0F6E5C);

    test('reproducen Korren dentro de una tolerancia imperceptible', () {
      final light = BrandNeutrals.from(korrenLight, BrandPalette.lightDefaults);
      expect(_distance(light.bg, _hex('#FBF3EA')), lessThan(24));
      expect(_distance(light.surfaceAlt, _hex('#F3E6D8')), lessThan(24));
      expect(_distance(light.border, _hex('#E7D8C8')), lessThan(24));
      expect(_distance(light.text, _hex('#2B2119')), lessThan(24));

      final dark = BrandNeutrals.from(korrenLight, BrandPalette.darkDefaults);
      expect(_distance(dark.bg, _hex('#1E1712')), lessThan(24));
      expect(_distance(dark.surfaceAlt, _hex('#352920')), lessThan(24));
      expect(_distance(dark.text, _hex('#F3E9DD')), lessThan(24));
    });

    test('reproducen Verra dentro de una tolerancia imperceptible', () {
      final light = BrandNeutrals.from(verraLight, BrandPalette.lightDefaults);
      expect(_distance(light.bg, _hex('#F2F7F1')), lessThan(24));
      expect(_distance(light.surfaceAlt, _hex('#E6F0E3')), lessThan(24));
      expect(_distance(light.border, _hex('#D6E5DA')), lessThan(24));
      expect(_distance(light.text, _hex('#12241F')), lessThan(24));

      final dark = BrandNeutrals.from(verraLight, BrandPalette.darkDefaults);
      expect(_distance(dark.bg, _hex('#0C1B17')), lessThan(24));
      expect(_distance(dark.surfaceAlt, _hex('#1A322B')), lessThan(24));
      expect(_distance(dark.text, _hex('#E7F2EE')), lessThan(24));
    });

    test('una marca cálida y una fría no comparten neutrales', () {
      final warm = BrandNeutrals.from(korrenLight, BrandPalette.lightDefaults);
      final cool = BrandNeutrals.from(verraLight, BrandPalette.lightDefaults);
      expect(_distance(warm.bg, cool.bg), greaterThan(10));
      expect(_distance(warm.surfaceAlt, cool.surfaceAlt), greaterThan(10));
      expect(_distance(warm.textMuted, cool.textMuted), greaterThan(10));
    });

    test('un primary sin matiz cae a los neutrales por defecto', () {
      final grey = BrandNeutrals.from(
        const Color(0xff707070),
        BrandPalette.lightDefaults,
      );
      expect(grey.bg, BrandPalette.lightDefaults.bg);
      expect(grey.text, BrandPalette.lightDefaults.text);
    });

    test('el documento gana sobre el neutral derivado', () {
      final palette = BrandPalette.fromJson(
        const {'primary': '#C1602E', 'bg': '#123456'},
        defaults: BrandPalette.lightDefaults,
      );
      expect(palette.bg, _hex('#123456'));
      expect(
        _distance(palette.surfaceAlt, _hex('#F3E6D8')),
        lessThan(24),
        reason: 'los neutrales no declarados siguen derivándose',
      );
    });

    test('el modo oscuro toma el matiz del primary claro', () {
      // Verra invierte primary y secondary al oscurecer: el matiz de identidad
      // vive en el primary claro, no en el oscuro.
      final config = BrandConfig.fromJson(const {
        'palettes': {
          'light': {'primary': '#0F6E5C'},
          'dark': {'primary': '#7EBF44'},
        },
      });
      expect(_distance(config.dark.bg, _hex('#0C1B17')), lessThan(24));
    });
  });

  group('derivaciones de BrandTokens', () {
    const tokens = BrandTokens(
      bg: Color(0xffFBF3EA),
      surface: Color(0xffFFFFFF),
      surfaceAlt: Color(0xffF3E6D8),
      primary: Color(0xffC1602E),
      onPrimary: Color(0xffFFFFFF),
      secondary: Color(0xffE8A33D),
      onSecondary: Color(0xff2B2119),
      text: Color(0xff2B2119),
      textMuted: Color(0xff8A7A6C),
      border: Color(0xffE7D8C8),
      success: Color(0xff4C8B5B),
      warning: Color(0xffD98E2B),
      danger: Color(0xffC1452F),
      headFont: 'Fredoka',
      bodyFont: 'Karla',
      radiusSm: 10,
      radiusMd: 18,
      radiusLg: 26,
    );

    test('el segundo stop del degradado mezcla 22% hacia blanco o negro', () {
      // onPrimary es claro, así que el degradado oscurece.
      expect(
        tokens.headerGradientEnd.computeLuminance(),
        lessThan(tokens.primary.computeLuminance()),
      );
      expect(
        _distance(tokens.headerGradientEnd, const Color(0xff964B24)),
        lessThan(12),
      );
    });

    test('el degradado aclara cuando onPrimary es oscuro', () {
      final dark = tokens.copyWith(onPrimary: const Color(0xff241A10));
      expect(
        dark.headerGradientEnd.computeLuminance(),
        greaterThan(dark.primary.computeLuminance()),
      );
    });

    test('el glow del timeline es 16% del acento', () {
      expect(tokens.timelineGlow(tokens.primary).a, closeTo(0.16, 0.001));
    });

    test('el velo de overlay es 12% del texto', () {
      expect(tokens.sheetBackdrop.a, closeTo(0.12, 0.001));
    });

    test('onAccent elige el color con más contraste', () {
      expect(tokens.onAccent(tokens.primary), tokens.surface);
      expect(tokens.onAccent(tokens.surfaceAlt), tokens.text);
    });
  });
}
