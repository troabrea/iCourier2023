import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icourier/design_system/core_components.dart';
import 'package:icourier/design_system/home_components.dart';
import 'package:icourier/domain/package_stage.dart';

import '../helpers/brand_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    initializeTestTranslations();
    await loadBrandFonts(includeGoogleFamilies: true);
  });

  final brands = Directory('whitelabel')
      .listSync()
      .whereType<File>()
      .where((file) =>
          file.path.endsWith('.json') && !file.path.endsWith('_schema.json'))
      .map((file) => file.uri.pathSegments.last.replaceFirst('.json', ''));
  for (final brand in brands) {
    for (final brightness in Brightness.values) {
      testWidgets('$brand ${brightness.name}: 320px and double text scale',
          (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final captureKey = GlobalKey();
        await tester.pumpWidget(brandTestApp(
          config: loadTestBrand(brand),
          brightness: brightness,
          child: Builder(
              builder: (context) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: const TextScaler.linear(2)),
                    child: SingleChildScrollView(
                        child: Column(children: [
                      RepaintBoundary(
                          key: captureKey,
                          child: const MacroStepper(stage: PackageStage.ruta)),
                      const StatusBadge(
                          stage: PackageStage.destino,
                          label: 'Disponible para entrega'),
                      HomeStatusCard(total: 4, groups: [
                        for (final stage in PackageStage.values.take(4))
                          HomeStageGroup(
                              stage: stage,
                              count: 1,
                              contents: 'Artículo de prueba',
                              onOpen: () {}),
                      ]),
                    ])),
                  )),
        ));
        await tester.pumpAndSettle();
        if (['bmcargo', 'dopack', 'blumbox', 'fixocargo', 'tupaq']
            .contains(brand)) {
          await expectLater(
              find.byKey(captureKey),
              matchesGoldenFile(
                  'goldens/stages_${brand}_${brightness.name}_large_text.png'));
        }
        expect(tester.takeException(), isNull);
        for (final label in [
          'Origen',
          'En tránsito',
          'En distribución',
          'Disponible'
        ]) {
          expect(find.text(label), findsWidgets);
        }
        expect(find.text('Disponible para entrega'), findsNothing);
        for (final label in ['En ruta', 'En destino', 'Disponibles']) {
          expect(find.text(label), findsNothing);
        }
      });
    }
  }
}
