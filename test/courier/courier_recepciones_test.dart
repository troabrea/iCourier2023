import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icourier/courier/courier_recepciones.dart';
import 'package:icourier/design_system/core_components.dart';
import 'package:icourier/design_system/home_components.dart';
import 'package:icourier/domain/package_stage.dart';
import 'package:icourier/services/model/recepcion.dart';

import '../helpers/brand_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    initializeTestTranslations();
    await loadBrandFonts();
  });

  testWidgets('agrupa las recepciones por estado cuando abre sin filtro', (
    tester,
  ) async {
    await _pumpReceptions(tester);

    expect(find.text('DISPONIBLES (1)'), findsOneWidget);
    expect(find.text('EN RUTA (2)'), findsOneWidget);
    expect(_visibleIds(tester), ['available', 'route-a', 'route-b']);
    expect(find.text(r'$10.00'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(PackageCard),
        matching: find.byIcon(Icons.chevron_right),
      ),
      findsNWidgets(3),
    );
    await expectLater(
      find.byType(RecepcionesPage),
      matchesGoldenFile('goldens/recepciones_agrupadas.png'),
    );
  });

  testWidgets('restaura los grupos cuando se elimina el filtro', (
    tester,
  ) async {
    await _pumpReceptions(tester, initialStage: PackageStage.ruta);

    expect(find.byType(BrandFilterChip), findsOneWidget);
    expect(find.byType(PackageCard), findsNWidgets(2));
    expect(find.text('EN RUTA (2)'), findsNothing);

    await tester.tap(
      find.descendant(
        of: find.byType(BrandFilterChip),
        matching: find.byIcon(Icons.close),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DISPONIBLES (1)'), findsOneWidget);
    expect(find.text('EN RUTA (2)'), findsOneWidget);
    expect(_visibleIds(tester), ['available', 'route-a', 'route-b']);
  });
}

Future<void> _pumpReceptions(
  WidgetTester tester, {
  PackageStage? initialStage,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    brandTestApp(
      config: loadTestBrand('bmcargo'),
      child: RecepcionesPage(
        recepciones: [
          _reception('route-a', status: 'En ruta', progress: 2),
          _reception(
            'available',
            status: 'Disponible',
            progress: 4,
            available: true,
          ),
          _reception('route-b', status: 'Embarcado', progress: 2),
        ],
        initialStage: initialStage,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<String> _visibleIds(WidgetTester tester) => tester
    .widgetList<PackageCard>(find.byType(PackageCard))
    .map((card) => card.package.recepcionID)
    .toList(growable: false);

Recepcion _reception(
  String id, {
  required String status,
  required int progress,
  bool available = false,
}) =>
    Recepcion(
      recepcionID: id,
      fecha: '2026.08.13',
      producto: 'Libra',
      suplidor: 'Proveedor',
      cantidadPaquetes: 1,
      contenido: 'Contenido $id',
      enviadoPor: '',
      totalPeso: '1',
      totalVolumen: '',
      totalNeto: '10.00',
      estatus: status,
      retenido: false,
      disponible: available,
      paquetes: const [],
      fotoPaqueteSmallUrl: '',
      fotoPaqueteUrl: '',
      fotoFacturaUrl: '',
      fechaHora: '2026-08-13T12:00:00',
      progreso: progress,
      numeroRastreo: 'tracking-$id',
    );
