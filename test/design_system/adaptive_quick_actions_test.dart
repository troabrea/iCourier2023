import 'package:flutter_test/flutter_test.dart';
import 'package:icourier/design_system/brand_foundations.dart';
import 'package:icourier/design_system/core_components.dart';
import 'package:icourier/design_system/overlay_components.dart';

import '../helpers/brand_test_app.dart';

/// The banner and the packages card own the first screen. These cover the rule
/// that keeps the quick actions from pushing them off it, which cannot be seen
/// on the simulators installed here — they are all large phones.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    initializeTestTranslations();
    await loadBrandFonts();
  });

  var opened = 0;

  List<QuickAction> actions() => [
        QuickAction(
          label: 'Ver Pre-Alertas',
          icon: BrandIcons.receptions,
          onTap: () => opened++,
        ),
        QuickAction(
          label: 'Rastrear Paquete',
          icon: BrandIcons.track,
          onTap: () => opened++,
        ),
        QuickAction(
          label: 'Consulta Histórica',
          icon: BrandIcons.history,
          onTap: () => opened++,
        ),
      ];

  Future<void> pump(WidgetTester tester, double room) async {
    opened = 0;
    await tester.pumpWidget(
      brandTestApp(
        config: loadTestBrand('bmcargo'),
        child: AdaptiveQuickActions(actions: actions(), room: room),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('con espacio de sobra las muestra en fila', (tester) async {
    await pump(tester, QuickActionList.heightFor(3) + 1);

    expect(find.text('Rastrear Paquete'), findsOneWidget);
    expect(find.text('Consulta Histórica'), findsOneWidget);
  });

  testWidgets('sin espacio se pliegan tras un botón', (tester) async {
    await pump(tester, QuickActionList.heightFor(3) - 1);

    expect(find.text('Rastrear Paquete'), findsNothing);
    expect(find.text('Más acciones'), findsOneWidget);
  });

  testWidgets('el botón abre las acciones y ejecutarlas cierra la hoja',
      (tester) async {
    await pump(tester, 0);

    await tester.tap(find.text('Más acciones'));
    await tester.pumpAndSettle();
    expect(find.text('Rastrear Paquete'), findsOneWidget);

    await tester.tap(find.text('Rastrear Paquete'));
    await tester.pumpAndSettle();

    expect(opened, 1);
    expect(find.text('Rastrear Paquete'), findsNothing);
  });

  testWidgets('una acción deshabilitada no ocupa espacio ni aparece',
      (tester) async {
    await tester.pumpWidget(
      brandTestApp(
        config: loadTestBrand('bmcargo'),
        child: AdaptiveQuickActions(
          room: QuickActionList.heightFor(1) + 1,
          actions: [
            QuickAction(
              label: 'Ver Pre-Alertas',
              icon: BrandIcons.receptions,
              enabled: false,
              onTap: () {},
            ),
            QuickAction(
              label: 'Rastrear Paquete',
              icon: BrandIcons.track,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Sólo cuenta la habilitada, así que cabe en fila.
    expect(find.text('Rastrear Paquete'), findsOneWidget);
    expect(find.text('Ver Pre-Alertas'), findsNothing);
  });
}
