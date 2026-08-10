import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:icourier/design_system/brand_foundations.dart';

/// Every glyph is painted as a tinted mask, so artwork that relies on a second
/// colour — typically a white knockout over a solid shape — collapses into a
/// filled blob on screen. These checks catch that before it ships.
void main() {
  const glyphs = <String, String>{
    'receptions': BrandIcons.receptions,
    'available': BrandIcons.available,
    'shipped': BrandIcons.shipped,
    'atDestination': BrandIcons.atDestination,
    'received': BrandIcons.received,
    'missingInvoice': BrandIcons.missingInvoice,
    'prealert': BrandIcons.prealert,
    'track': BrandIcons.track,
    'calculator': BrandIcons.calculator,
    'history': BrandIcons.history,
    'news': BrandIcons.news,
    'branches': BrandIcons.branches,
    'information': BrandIcons.information,
    'whatsapp': BrandIcons.whatsapp,
    'services': BrandIcons.services,
    'questions': BrandIcons.questions,
    'uploadInvoice': BrandIcons.uploadInvoice,
    'refresh': BrandIcons.refresh,
    'user': BrandIcons.user,
    'phone': BrandIcons.phone,
    'email': BrandIcons.email,
    'schedule': BrandIcons.schedule,
    'mapMarker': BrandIcons.mapMarker,
  };

  final whiteFill = RegExp(r'fill:\s*#(?:fff|ffffff)\b', caseSensitive: false);

  group('glifos de marca', () {
    test('todos los assets referenciados existen', () {
      for (final entry in glyphs.entries) {
        expect(
          File(entry.value).existsSync(),
          isTrue,
          reason: '${entry.key} apunta a ${entry.value}, que no existe',
        );
      }
    });

    test('están declarados en pubspec.yaml', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final entry in glyphs.entries) {
        expect(
          pubspec.contains(entry.value),
          isTrue,
          reason: '${entry.value} no está declarado como asset',
        );
      }
    });

    test('ninguno usa blanco en negativo, que el teñido destruiría', () {
      for (final entry in glyphs.entries) {
        final source = File(entry.value).readAsStringSync();
        expect(
          whiteFill.hasMatch(source),
          isFalse,
          reason: '${entry.key} (${entry.value}) dibuja su detalle en blanco; '
              'al teñirlo con un token se convierte en una mancha sólida',
        );
      }
    });
  });
}
