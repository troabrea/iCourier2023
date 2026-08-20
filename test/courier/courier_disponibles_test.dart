import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/courier/courier_disponibles.dart';
import 'package:icourier/design_system/core_components.dart';
import 'package:icourier/services/model/empresa.dart';
import 'package:icourier/services/model/recepcion.dart';
import 'package:icourier/theme/brand_config.dart';

import '../helpers/brand_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    initializeTestTranslations();
    await loadBrandFonts();
  });

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<BrandConfig>(loadTestBrand('bmcargo'));
  });

  tearDown(() => GetIt.I.reset());

  testWidgets('resume todos los disponibles sin controles de selección', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final empresa = Empresa.empty()
      ..hasNotifyModule = true
      ..hasPaymentsModule = true
      ..hasDelivery = false;
    final goldenKey = GlobalKey();

    await tester.pumpWidget(
      brandTestApp(
        config: GetIt.I<BrandConfig>(),
        child: RepaintBoundary(
          key: goldenKey,
          child: DisponiblesPage(
            disponibles: [_package()],
            empresa: empresa,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final summary = find.byType(SelectionSummaryBar);
    expect(
      find.descendant(of: summary, matching: find.text('Retirar')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: summary, matching: find.text('1 paquete')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: summary, matching: find.text('Pagar')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: summary, matching: find.text(r'$344.14')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: summary,
        matching: find.byIcon(Icons.inventory_2_outlined),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: summary,
        matching: find.byIcon(Icons.credit_card_outlined),
      ),
      findsOneWidget,
    );
    final summaryButtons = find.descendant(
      of: summary,
      matching: find.byType(OutlinedButton),
    );
    expect(summaryButtons, findsNWidgets(2));
    expect(
      tester.getTopLeft(summaryButtons.at(0)).dy,
      tester.getTopLeft(summaryButtons.at(1)).dy,
    );
    expect(find.byType(SelectableRow), findsNothing);

    await expectLater(
      find.byKey(goldenKey),
      matchesGoldenFile('goldens/disponibles_bmcargo_light.png'),
    );
  });

  testWidgets('muestra cantidad y total cuando no hay acciones disponibles', (
    tester,
  ) async {
    final empresa = Empresa.empty()
      ..hasNotifyModule = false
      ..hasPaymentsModule = false
      ..hasDelivery = false;

    await tester.pumpWidget(
      brandTestApp(
        config: GetIt.I<BrandConfig>(),
        child: DisponiblesPage(
          disponibles: [_package()],
          empresa: empresa,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final summary = find.byType(SelectionSummaryBar);
    expect(
      find.descendant(of: summary, matching: find.text('Cantidad')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: summary, matching: find.text('Total')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: summary, matching: find.text('Retirar')),
      findsNothing,
    );
    expect(
      find.descendant(of: summary, matching: find.text('Pagar')),
      findsNothing,
    );
  });
}

Recepcion _package() => Recepcion(
      recepcionID: 'reception-1',
      fecha: '2026.08.11',
      producto: 'Libra',
      suplidor: 'Thriftbooks',
      cantidadPaquetes: 1,
      contenido: 'Libro',
      enviadoPor: '',
      totalPeso: '1',
      totalVolumen: '',
      totalNeto: '344.14',
      estatus: 'Disponible',
      retenido: false,
      disponible: true,
      paquetes: const [],
      fotoPaqueteSmallUrl: '',
      fotoPaqueteUrl: '',
      fotoFacturaUrl: '',
      fechaHora: '2026-08-11T12:00:00',
      progreso: 3,
      numeroRastreo: '9241990376126775804666',
    );
