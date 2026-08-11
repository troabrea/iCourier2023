import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icourier/design_system/overlay_components.dart';
import 'package:icourier/services/model/login_model.dart';

import '../helpers/brand_test_app.dart';

/// Forgetting an account signs the customer out of it, and on the last account
/// it drops them at the login screen. These cover the guard that keeps a slip
/// from doing that, which cannot be exercised against a real account.
/// Avanza el reloj en pasos de un frame.
///
/// Un solo `pump` largo no sirve: el primer tick del ticker sólo fija el
/// origen del tiempo y reporta cero, así que la animación no avanzaría.
Future<void> _hold(WidgetTester tester, Duration total) async {
  const frame = Duration(milliseconds: 50);
  for (var elapsed = Duration.zero; elapsed < total; elapsed += frame) {
    await tester.pump(frame);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    initializeTestTranslations();
    await loadBrandFonts();
  });

  UserAccount account() => UserAccount(
        sessionId: 's',
        nombre: 'Temistocles Roa',
        userAccount: 'BM-096791',
        password: 'x',
      );

  Future<void> pumpSwitcher(
    WidgetTester tester, {
    required ValueChanged<UserAccount> onDelete,
  }) async {
    final only = account();
    await tester.pumpWidget(
      brandTestApp(
        config: loadTestBrand('bmcargo'),
        child: AccountSwitcher(
          accounts: [only],
          activeAccount: only.userAccount,
          onSelect: (_) {},
          onDelete: onDelete,
          onAdd: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('la cuenta activa ofrece eliminarse', (tester) async {
    await pumpSwitcher(tester, onDelete: (_) {});

    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    expect(find.text('Cambiar Cuenta / Cerrar Sesión'), findsOneWidget);
    // El botón rojo suelto de cerrar sesión ya no existe.
    expect(find.text('Cerrar Sesión'), findsNothing);
  });

  testWidgets('un toque en el botón destructivo no borra', (tester) async {
    var deleted = 0;
    await pumpSwitcher(tester, onDelete: (_) => deleted++);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Mantén para eliminar'), findsOneWidget);

    await tester.tap(find.text('Mantén para eliminar'));
    await tester.pumpAndSettle();

    expect(deleted, 0);
  });

  testWidgets('soltar antes de tiempo no borra', (tester) async {
    var deleted = 0;
    await pumpSwitcher(tester, onDelete: (_) => deleted++);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    final gesture = await tester.press(find.text('Mantén para eliminar'));
    await _hold(tester, const Duration(milliseconds: 600));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(deleted, 0);
  });

  testWidgets('mantener presionado sí borra', (tester) async {
    var deleted = 0;
    await pumpSwitcher(tester, onDelete: (_) => deleted++);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    final gesture = await tester.press(find.text('Mantén para eliminar'));
    await _hold(tester, const Duration(milliseconds: 1100));
    // Soltar después de que el botón ya desapareció no debe reventar.
    await gesture.up();
    await tester.pumpAndSettle();

    expect(deleted, 1);
  });

  testWidgets('la tecnología asistiva lo activa como botón', (tester) async {
    var deleted = 0;
    await pumpSwitcher(tester, onDelete: (_) => deleted++);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    final handle = tester.ensureSemantics();
    // Sin gesto: VoiceOver invoca la acción, no arrastra el dedo por la
    // pantalla, así que el guard del hold no puede ser el único camino.
    final node = tester.getSemantics(find.bySemanticsLabel('Sí, eliminar'));
    // ignore: deprecated_member_use
    tester.binding.pipelineOwner.semanticsOwner!.performAction(
      node.id,
      SemanticsAction.tap,
    );
    await tester.pumpAndSettle();
    handle.dispose();

    expect(deleted, 1);
  });
}
