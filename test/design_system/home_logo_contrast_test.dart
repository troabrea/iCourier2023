import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icourier/design_system/core_components.dart';
import 'package:icourier/theme/brand_config.dart';

import '../helpers/brand_test_app.dart';

void main() {
  setUpAll(() async {
    initializeTestTranslations();
    await loadBrandFonts();
  });

  for (final brightness in Brightness.values) {
    for (final index in [0, 2]) {
      testWidgets('CPS home logo is visible: ${brightness.name}, tab $index',
          (tester) async {
        final config = loadTestBrand('cps');
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
            if (1.05 / (pixel.computeLuminance() + 0.05) >= 3) visible++;
            total++;
          }
        }
        image!.dispose();
        expect(visible / total, greaterThan(0.05),
            reason: 'The home mark must have visible artwork on its backdrop.');
      });
    }
  }
}
