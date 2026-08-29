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
              opened = await showDialog<bool>(
                    context: context,
                    builder: (context) => EmergingNewsDialog(
                      announcement: EmergingNewsAnnouncement(
                        imageUrl: 'https://cdn.example.com/alert.png',
                        news: _news(),
                      ),
                      imageProvider: _image,
                    ),
                  ) ??
                  false;
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

    await tester.tap(find.text('Ver más'));
    await tester.pumpAndSettle();

    expect(opened, isTrue);
    expect(find.byType(EmergingNewsDialog), findsNothing);
  });

  testWidgets('keeps an image-only campaign free of empty controls', (
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
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => EmergingNewsDialog(
                announcement: const EmergingNewsAnnouncement(
                  imageUrl: 'https://cdn.example.com/alert.png',
                ),
                imageProvider: _goldenImage,
              ),
            ),
            child: const Text('Mostrar'),
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => precacheImage(
        _goldenImage,
        tester.element(find.text('Mostrar')),
      ),
    );

    await tester.tap(find.text('Mostrar'));
    await tester.pumpAndSettle();

    expect(find.text('Ver más'), findsNothing);
    expect(find.byIcon(Icons.close), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(EmergingNewsDialog), findsNothing);
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
