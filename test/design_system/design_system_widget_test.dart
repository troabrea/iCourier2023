import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icourier/design_system/brand_states.dart';
import 'package:icourier/design_system/calculator_components.dart';
import 'package:icourier/design_system/core_components.dart';
import 'package:icourier/domain/package_stage.dart';
import 'package:icourier/services/model/recepcion.dart';
import 'package:icourier/theme/brand_config.dart';

import '../helpers/brand_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    initializeTestTranslations();
    await loadBrandFonts();
  });

  testWidgets('muestra carga, vacío y error recuperable', (tester) async {
    final config = loadTestBrand('bmcargo');

    await tester.pumpWidget(
      brandTestApp(config: config, child: const BrandSkeleton(rows: 3)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Semantics), findsWidgets);

    await tester.pumpWidget(
      brandTestApp(
        config: config,
        child: const BrandEmptyState(messageKey: 'no_resultados'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No hay resultados'), findsOneWidget);

    var retried = false;
    await tester.pumpWidget(
      brandTestApp(
        config: config,
        child: BrandErrorState(onRetry: () => retried = true),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reintentar'));
    expect(retried, isTrue);
  });

  testWidgets('retenido deshabilita selección y usa estado de advertencia',
      (tester) async {
    final config = loadTestBrand('bmcargo');
    final package = _package(retained: true);
    var toggled = false;

    await tester.pumpWidget(
      brandTestApp(
        config: config,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const StatusBadge(
              stage: PackageStage.disponible,
              retained: true,
            ),
            SelectableRow(
              package: package,
              checked: false,
              onToggle: (_) => toggled = true,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // La fila retenida se atenúa y no acepta selección.
    expect(find.byType(Opacity), findsWidgets);
    await tester.tap(find.byType(SelectableRow), warnIfMissed: false);
    expect(toggled, isFalse);
  });

  testWidgets('capacidades ocultan puntos y pago', (tester) async {
    final config = loadTestBrand('fixocargo');

    await tester.pumpWidget(
      brandTestApp(
        config: config,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandHeader(
              greeting: 'Bienvenido',
              account: 'FX-100',
              points: 900,
              capabilities: BrandCapabilities(points: false),
            ),
            SelectionSummaryBar(
              count: 1,
              total: 100,
              currency: 'RD\$',
              capabilities: BrandCapabilities(payments: false),
              onPay: _noop,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('900'), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('componentes soportan escalado de texto al 200%', (tester) async {
    final config = loadTestBrand('fixocargo');
    await tester.pumpWidget(
      brandTestApp(
        config: config,
        textScaler: const TextScaler.linear(2),
        child: const BrandEmptyState(messageKey: 'no_resultados'),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('campo numérico acepta separador decimal local', (tester) async {
    final config = loadTestBrand('bmcargo');
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      brandTestApp(
        config: config,
        child: BigNumberField(
          label: 'Peso',
          unit: 'lb',
          controller: controller,
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '1,25');

    expect(controller.text, '1,25');
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}

Recepcion _package({required bool retained}) => Recepcion(
      recepcionID: 'RD-1',
      fecha: '2026-08-10',
      producto: 'Aéreo',
      suplidor: 'Amazon',
      cantidadPaquetes: 1,
      contenido: 'Artículos personales',
      enviadoPor: 'Amazon',
      totalPeso: '2.5',
      totalVolumen: '0',
      totalNeto: '100',
      estatus: 'Disponible',
      retenido: retained,
      disponible: true,
      paquetes: const [],
      fotoPaqueteSmallUrl: '',
      fotoPaqueteUrl: '',
      fotoFacturaUrl: '',
      fechaHora: '2026-08-10T10:00:00',
      progreso: 3,
      numeroRastreo: '1Z999',
    );
