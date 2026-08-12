import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icourier/design_system/content_components.dart';
import 'package:icourier/design_system/overlay_components.dart';
import 'package:icourier/services/model/sucursal.dart';

import '../helpers/brand_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    initializeTestTranslations();
    await loadBrandFonts();
  });

  Sucursal branchWith(String horario) => Sucursal(
        registroId: '1',
        empresa: 'demo',
        nombre: 'Sucursal Principal',
        codigo: 'SDQ',
        direccion: 'Av. Principal, Santo Domingo',
        ciudad: 'Santo Domingo',
        pais: 'República Dominicana',
        horario: horario,
        telefonoOficina: '809-000-0000',
        telefonoVentas: '',
        email: 'sucursal@demo.do',
        imagenId: '',
        latitud: 18.4861,
        longitud: -69.9312,
        orden: 1,
        deleted: false,
      );

  // A Wednesday mid-morning, well inside a weekday schedule.
  final openHour = DateTime(2026, 8, 12, 10, 30);

  group('BranchCard', () {
    testWidgets('reads a schedule it understands into today\'s state',
        (tester) async {
      await tester.pumpWidget(
        brandTestApp(
          config: loadTestBrand('fixocargo'),
          child: BranchRow(
            branch: branchWith('Lunes a viernes · 8:00–17:00'),
            at: openHour,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Abierto'), findsOneWidget);
      expect(find.text('Lunes a viernes · 8:00–17:00'), findsNothing);
    });

    testWidgets('prints the schedule verbatim when it cannot be read',
        (tester) async {
      const unreadable = 'Consultar horario en la sucursal';
      await tester.pumpWidget(
        brandTestApp(
          config: loadTestBrand('fixocargo'),
          child: BranchRow(branch: branchWith(unreadable), at: openHour),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(unreadable), findsOneWidget);
      expect(find.textContaining('Abierto'), findsNothing);
      expect(find.textContaining('Cerrado'), findsNothing);
    });

    testWidgets('crowns the closest branch and names it for a screen reader',
        (tester) async {
      await tester.pumpWidget(
        brandTestApp(
          config: loadTestBrand('fixocargo'),
          child: BranchRow(
            branch: branchWith('Lunes a viernes · 8:00–17:00'),
            distanceKm: 1.2,
            nearest: true,
            at: openHour,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('La más cercana'), findsOneWidget);
      expect(
        tester
            .getSemantics(find.byType(BranchRow))
            .label
            .contains('La más cercana'),
        isTrue,
      );
    });

    testWidgets('keeps the map tap and the detail tap apart', (tester) async {
      var tapped = 0;
      var opened = 0;
      await tester.pumpWidget(
        brandTestApp(
          config: loadTestBrand('fixocargo'),
          child: BranchRow(
            branch: branchWith('Lunes a viernes · 8:00–17:00'),
            onTap: () => tapped++,
            onMore: () => opened++,
            at: openHour,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sucursal Principal'));
      await tester.pumpAndSettle();
      expect(tapped, 1, reason: 'el cuerpo mueve el mapa');
      expect(opened, 0, reason: 'el cuerpo no abre el sheet');

      await tester.tap(find.bySemanticsLabel('Ver detalle'));
      await tester.pumpAndSettle();
      expect(opened, 1, reason: 'el control de acciones abre el sheet');
      expect(tapped, 1, reason: 'y no mueve el mapa además');
    });

    testWidgets('states a sub-kilometre distance in metres', (tester) async {
      await tester.pumpWidget(
        brandTestApp(
          config: loadTestBrand('fixocargo'),
          child: BranchRow(
            branch: branchWith(''),
            distanceKm: 0.42,
            at: openHour,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('420 m'), findsOneWidget);
    });

    testWidgets('carries no distance badge before location resolves',
        (tester) async {
      await tester.pumpWidget(
        brandTestApp(
          config: loadTestBrand('fixocargo'),
          child: BranchRow(branch: branchWith(''), at: openHour),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('km'), findsNothing);
      expect(find.textContaining(' m'), findsNothing);
    });
  });

  group('BranchList', () {
    testWidgets('survives a doubled text scale and a long name',
        (tester) async {
      final long = Sucursal(
        registroId: '9',
        empresa: 'demo',
        nombre: 'Sucursal Plaza Central Av. 27 de Febrero, Segundo Nivel',
        codigo: 'LNG',
        direccion:
            'Av. Winston Churchill esq. Av. Gustavo Mejía Ricart, Plaza Blue '
            'Mall, tercer nivel, local 312-B',
        ciudad: 'Santo Domingo',
        pais: 'República Dominicana',
        horario: 'Lunes a viernes · 8:00–17:00',
        telefonoOficina: '809-000-0000',
        telefonoVentas: '',
        email: '',
        imagenId: '',
        latitud: 18.4861,
        longitud: -69.9312,
        orden: 1,
        deleted: false,
      );
      await tester.pumpWidget(
        brandTestApp(
          config: loadTestBrand('fixocargo'),
          textScaler: const TextScaler.linear(2),
          // The row ships inside a ListView, so height is the one axis it never
          // has to fit into. Width is where a name, a badge and a control
          // compete, and that is what this pins.
          child: SingleChildScrollView(
            child: BranchList(
              children: [
                BranchRow(branch: long, distanceKm: 12.4, nearest: true,
                    at: openHour),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('separates rows with one hairline, not with gaps',
        (tester) async {
      await tester.pumpWidget(
        brandTestApp(
          config: loadTestBrand('fixocargo'),
          child: BranchList(
            children: [
              BranchRow(branch: branchWith(''), at: openHour),
              BranchRow(branch: branchWith(''), at: openHour),
              BranchRow(branch: branchWith(''), at: openHour),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BranchRow), findsNWidgets(3));
      expect(find.byType(Divider), findsNWidgets(2));
    });
  });

  group('BranchSheet', () {
    testWidgets('leads with today, and still prints the whole week',
        (tester) async {
      const horario = 'Lunes a viernes · 8:00–17:00';
      await tester.pumpWidget(
        brandTestApp(
          config: loadTestBrand('fixocargo'),
          child: BranchSheet(branch: branchWith(horario), at: openHour),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Abierto'), findsOneWidget);
      expect(find.text(horario), findsOneWidget);
    });

    testWidgets('carries the distance beside the name', (tester) async {
      await tester.pumpWidget(
        brandTestApp(
          config: loadTestBrand('fixocargo'),
          child: BranchSheet(
            branch: branchWith(''),
            distanceKm: 0.86,
            at: openHour,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('860 m'), findsOneWidget);
    });

    testWidgets('shows no state badge for a schedule it cannot read',
        (tester) async {
      await tester.pumpWidget(
        brandTestApp(
          config: loadTestBrand('fixocargo'),
          child: BranchSheet(
            branch: branchWith('Horario variable'),
            at: openHour,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Horario variable'), findsOneWidget);
      expect(find.textContaining('Abierto'), findsNothing);
    });
  });
}
