import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icourier/design_system/core_components.dart';
import 'package:icourier/theme/brand_config.dart';
import 'package:icourier/theme/brand_config_validator.dart';

import '../helpers/brand_test_app.dart';

void main() {
  setUpAll(() async {
    initializeTestTranslations();
    await loadBrandFonts();
  });

  test('only Inbox opts into a logo tint', () {
    for (final file in Directory('whitelabel').listSync().whereType<File>()) {
      if (!file.path.endsWith('.json') || file.path.endsWith('_schema.json')) {
        continue;
      }
      final config = BrandConfig.fromJson(
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
      );
      expect(config.assets.logoMarkTint,
          config.slug == 'inbox' ? const Color(0xff3ab8eb) : isNull,
          reason: file.path);
    }
  });

  test('rejects malformed logo tint configuration', () {
    final json = jsonDecode(File('whitelabel/inbox.json').readAsStringSync())
        as Map<String, dynamic>;
    (json['assets'] as Map<String, dynamic>)['logoMarkTint'] = 'blue';
    expect(() => BrandConfigValidator.validate(json), throwsFormatException);
  });

  for (final brightness in Brightness.values) {
    for (final index in [0, 2]) {
      testWidgets(
          'Inbox home logo uses its blue: ${brightness.name}, tab $index',
          (tester) async {
        final config = loadTestBrand('inbox');
        final key = GlobalKey();
        await tester.pumpWidget(brandTestApp(
          config: config,
          brightness: brightness,
          child: RepaintBoundary(
            key: key,
            child: BrandTabBar(
              modules: BrandNavigationConfig.standard().tabs,
              index: index,
              onTap: (_) {},
              logoMark: config.assets.logoMark,
              logoMarkTint: config.assets.logoMarkTint,
            ),
          ),
        ));
        await tester.runAsync(() => precacheImage(
              AssetImage(config.assets.logoMark),
              tester.element(find.byType(BrandTabBar)),
            ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final origin = tester.getTopLeft(find.byKey(key));
        final rect = tester.getRect(find.byType(Image)).shift(-origin);
        final image = await tester.runAsync(() => boundary.toImage());
        final bytes = await tester.runAsync(
          () => image!.toByteData(format: ui.ImageByteFormat.rawRgba),
        );
        var visible = 0;
        var total = 0;
        for (var y = rect.top.ceil(); y < rect.bottom.floor(); y++) {
          for (var x = rect.left.ceil(); x < rect.right.floor(); x++) {
            final offset = (y * image!.width + x) * 4;
            final pixel = Color.fromARGB(255, bytes!.getUint8(offset),
                bytes.getUint8(offset + 1), bytes.getUint8(offset + 2));
            if (pixel.b > pixel.r + 0.2 && pixel.g > pixel.r + 0.15) {
              visible++;
            }
            total++;
          }
        }
        image!.dispose();
        await expectLater(
          find.byKey(key),
          matchesGoldenFile('goldens/inbox_tab_${brightness.name}_$index.png'),
        );
        expect(visible / total, greaterThan(0.05),
            reason:
                'The Inbox mark must have visible blue artwork on its white backdrop.');
      });
    }
  }
}
