import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icourier/noticas/emerging_news_coordinator.dart';
import 'package:icourier/noticas/emerging_news_dialog.dart';
import 'package:icourier/services/model/noticia.dart';

import '../helpers/brand_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    initializeTestTranslations();
    await loadBrandFonts();
    await _loadMaterialIcons();
  });

  testWidgets('shows news context and opens the matching detail action', (
    tester,
  ) async {
    var opened = false;
    await tester.pumpWidget(
      brandTestApp(
        config: loadTestBrand('bmcargo'),
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              opened = await showEmergingNewsDialog(
                context,
                announcement: EmergingNewsAnnouncement(
                  imageUrl: 'https://cdn.example.com/alert.png',
                  news: _news(),
                ),
                imageProvider: _image,
                imageAspectRatio: 1,
              );
            },
            child: const Text('Mostrar'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mostrar'));
    await tester.pumpAndSettle();

    expect(find.text('Operación especial'), findsOneWidget);
    final preview = tester.widget<Text>(
      find.text('Conoce los detalles de nuestro horario especial.'),
    );
    expect(preview.maxLines, 2);
    expect(preview.overflow, TextOverflow.ellipsis);
    expect(
      find.byKey(const ValueKey('emerging-news-footer-note')),
      findsNothing,
    );
    expect(find.byIcon(Icons.close_rounded), findsNothing);

    await tester.tap(find.text('Ver más'));
    await tester.pumpAndSettle();

    expect(opened, isTrue);
    expect(find.byType(EmergingNewsDialog), findsNothing);
  });

  testWidgets('uses the campaign dimensions and closes from the barrier', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      brandTestApp(
        config: loadTestBrand('bmcargo'),
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showEmergingNewsDialog(
              context,
              announcement: const EmergingNewsAnnouncement(
                imageUrl: 'https://cdn.example.com/alert.png',
              ),
              imageProvider: _goldenImage,
              imageAspectRatio: _goldenAspectRatio,
            ),
            child: const Text('Mostrar'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mostrar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    final entrance = tester.widget<SlideTransition>(
      find.byKey(const ValueKey('emerging-news-roll-down')),
    );
    expect(entrance.position.value.dy, lessThan(0));

    await tester.pumpAndSettle();

    final cardSize = tester.getSize(
      find.byKey(const ValueKey('emerging-news-card')),
    );
    expect(cardSize.width, closeTo(390 * 0.8, 0.01));
    expect(cardSize.height, lessThan(844 * 0.6));
    expect(find.text('Ver más'), findsNothing);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
    expect(find.text('Tocar fuera para cerrar'), findsOneWidget);
    expect(
      tester
          .widget<Image>(
            find.descendant(
              of: find.byType(EmergingNewsDialog),
              matching: find.byType(Image),
            ),
          )
          .fit,
      BoxFit.contain,
    );

    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();

    expect(find.byType(EmergingNewsDialog), findsNothing);
  });

  testWidgets('gives an image-only campaign subtle dismissal guidance', (
    tester,
  ) async {
    await tester.pumpWidget(
      brandTestApp(
        config: loadTestBrand('bmcargo'),
        child: EmergingNewsDialog(
          announcement: const EmergingNewsAnnouncement(
            imageUrl: 'https://cdn.example.com/alert.png',
          ),
          imageProvider: _goldenImage,
          imageAspectRatio: _goldenAspectRatio,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ver más'), findsNothing);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
    expect(find.text('Tocar fuera para cerrar'), findsOneWidget);
  });

  testWidgets('remains usable with large text on a compact phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      brandTestApp(
        config: loadTestBrand('tupaq'),
        textScaler: const TextScaler.linear(2),
        child: EmergingNewsDialog(
          announcement: EmergingNewsAnnouncement(
            imageUrl: 'https://cdn.example.com/alert.png',
            news: _news(),
          ),
          imageProvider: _goldenImage,
          imageAspectRatio: _goldenAspectRatio,
        ),
      ),
    );
    await tester.runAsync(
      () => precacheImage(
        _goldenImage,
        tester.element(find.byType(EmergingNewsDialog)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Ver más'));
    await expectLater(
      find.byType(EmergingNewsDialog),
      matchesGoldenFile('goldens/emerging_news_compact_200_text.png'),
    );
    await tester.tap(find.text('Ver más'));
    await tester.pumpAndSettle();

    expect(find.byType(EmergingNewsDialog), findsNothing);
    expect(find.text('Ver más'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final fixture in [
    (
      brand: 'tupaq',
      brightness: Brightness.light,
      golden: 'goldens/emerging_news_tupaq_light.png',
    ),
    (
      brand: 'fixocargo',
      brightness: Brightness.dark,
      golden: 'goldens/emerging_news_fixocargo_dark.png',
    ),
  ]) {
    testWidgets('matches ${fixture.brand} ${fixture.brightness.name}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox.expand())),
      );
      await tester.runAsync(
        () => precacheImage(
          _goldenImage,
          tester.element(find.byType(Scaffold)),
        ),
      );

      await tester.pumpWidget(
        brandTestApp(
          config: loadTestBrand(fixture.brand),
          brightness: fixture.brightness,
          child: EmergingNewsDialog(
            announcement: EmergingNewsAnnouncement(
              imageUrl: 'asset://amazon',
              news: _news(),
            ),
            imageProvider: _goldenImage,
            imageAspectRatio: _goldenAspectRatio,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(EmergingNewsDialog),
        matchesGoldenFile(fixture.golden),
      );
    });
  }
}

final ImageProvider<Object> _image = MemoryImage(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII=',
  ),
);

final ImageProvider<Object> _goldenImage = MemoryImage(
  File('images/amazon.png').readAsBytesSync(),
);

const double _goldenAspectRatio = 286 / 176;

Future<void> _loadMaterialIcons() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.path;
  final file = File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/'
    'MaterialIcons-Regular.otf',
  );
  final loader = FontLoader('MaterialIcons');
  loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
  await loader.load();
}

Noticia _news() => Noticia(
      registroId: 'news-42',
      empresa: 'company',
      fecha: DateTime(2026, 8, 29),
      titulo: 'Operación especial',
      resumen: 'Conoce los detalles de nuestro horario especial.',
      contenido: 'Contenido completo.',
      url: '',
      deleted: false,
    );
