import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icourier/design_system/core_components.dart';
import 'package:icourier/theme/brand_theme.dart';
import 'package:icourier/theme/brand_tokens.dart';

import '../helpers/brand_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    initializeTestTranslations();
    await loadBrandFonts();
  });

  test('la escala de Blumbox conserva el cuerpo y las demás marcas', () {
    final configs = Directory('whitelabel').listSync().whereType<File>().where(
          (file) =>
              file.path.endsWith('.json') &&
              !file.path.endsWith('_schema.json'),
        );
    for (final file in configs) {
      final slug = file.uri.pathSegments.last.replaceAll('.json', '');
      final config = loadTestBrand(slug);
      for (final brightness in Brightness.values) {
        final theme = brightness == Brightness.light
            ? BrandTheme.light(config)
            : BrandTheme.dark(config);
        final tokens = theme.extension<BrandTokens>()!;
        expect(tokens.body(15).fontSize, 15, reason: slug);
        expect(tokens.body(15).fontFamily, config.bodyFont, reason: slug);
        if (slug == 'blumbox') {
          expect(tokens.head(24).fontSize, closeTo(21.6, 0.001));
        } else {
          expect(tokens.head(24).fontSize, 24, reason: slug);
          expect(theme.textTheme.titleLarge!.fontSize, 20, reason: slug);
        }
      }
    }
  });

  for (final width in [375.0, 393.0, 440.0]) {
    for (final scale in [1.0, 1.2]) {
      testWidgets(
        'Blumbox muestra el título completo a $width con escala $scale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 900);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            _app(
              scale: scale,
              child: const ScreenHeader.tab(
                title: 'Información Adicional',
                trailing: SizedBox.square(
                  dimension: 44,
                  child: Icon(Icons.chat_bubble_outline),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final title = tester.renderObject<RenderParagraph>(
            find.text('Información Adicional'),
          );
          expect(title.didExceedMaxLines, isFalse);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('Blumbox muestra TEMISTOCLES a $width con sus acciones', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _app(
          child: BrandHeader(
            greeting: 'TEMISTOCLES',
            account: 'BB-060326',
            unread: 13,
            capabilities: loadTestBrand('blumbox').capabilities,
            onContact: () {},
            onCarnet: () {},
            onMessages: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final name = tester.renderObject<RenderParagraph>(
        find.text('TEMISTOCLES'),
      );
      expect(name.didExceedMaxLines, isFalse);
      expect(tester.takeException(), isNull);
    });
  }
}

Widget _app({required Widget child, double scale = 1}) => MaterialApp(
      theme: BrandTheme.light(loadTestBrand('blumbox')),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(body: Align(alignment: Alignment.topCenter, child: child)),
    );
