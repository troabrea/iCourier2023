import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:icourier/apps/appinfo.dart';
import 'package:icourier/apps/bmcargo/appinfo_bmcargo.dart';
import 'package:icourier/courier/courier_historia_paquete.dart';
import 'package:icourier/courier/crear_postalerta.dart';
import 'package:icourier/navigation/app_router.dart';
import 'package:icourier/navigation/app_routes.dart';
import 'package:icourier/navigation/router_session.dart';
import 'package:icourier/services/app_events.dart';
import 'package:icourier/services/courier_service.dart';
import 'package:icourier/services/model/recepcion.dart';
import 'package:icourier/theme/brand_theme.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/brand_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initializeTestTranslations);

  setUp(() async {
    await GetIt.I.reset();
    SharedPreferences.setMockInitialValues({});
    GetIt.I.registerSingleton<AppInfo>(BmcargoAppInfo());
    GetIt.I.registerSingleton<CourierService>(CourierService());
  });

  tearDown(() => GetIt.I.reset());

  testWidgets('oculta la post-alerta para un paquete no retenido sin factura', (
    tester,
  ) async {
    await tester.pumpWidget(
      brandTestApp(
        config: loadTestBrand('bmcargo'),
        child: HistoricoPaquetePage(recepcion: _package()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Creación Post-Alerta'), findsNothing);
    expect(find.text('Adjuntar factura'), findsNothing);
  });

  testWidgets('ofrece adjuntar la factura cuando el paquete está retenido', (
    tester,
  ) async {
    await tester.pumpWidget(
      brandTestApp(
        config: loadTestBrand('bmcargo'),
        child: HistoricoPaquetePage(recepcion: _package(retained: true)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Retenido — Falta factura'), findsOneWidget);
    expect(find.text('Adjuntar factura'), findsOneWidget);
  });

  testWidgets('la ruta de factura rechaza post-alertas para no retenidos', (
    tester,
  ) async {
    final fixture = _package();
    final route = await _routerAtInvoice(fixture);
    addTearDown(() {
      route.router.dispose();
      route.session.dispose();
    });

    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('es'),
        theme: BrandTheme.light(loadTestBrand('bmcargo')),
        routerConfig: route.router,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HistoricoPaquetePage), findsOneWidget);
    expect(find.byType(CrearPostAlertaPage), findsNothing);
  });

  testWidgets('la ruta de factura permite post-alertas para retenidos', (
    tester,
  ) async {
    final fixture = _package(retained: true);
    final route = await _routerAtInvoice(fixture);
    addTearDown(() {
      route.router.dispose();
      route.session.dispose();
    });

    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('es'),
        theme: BrandTheme.light(loadTestBrand('bmcargo')),
        routerConfig: route.router,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CrearPostAlertaPage), findsOneWidget);
  });
}

Future<({GoRouter router, RouterSession session})> _routerAtInvoice(
  Recepcion fixture,
) async {
  final preferences = await SharedPreferences.getInstance();
  final session = RouterSession(
    initiallyLoggedIn: true,
    loginChanges: Event<LoginChanged>(),
  );
  final router = AppRouter.create(
    config: loadTestBrand('bmcargo'),
    session: session,
    preferences: preferences,
    defaultTabIndex: 0,
  );
  router.go(AppRoutes.invoice(fixture.recepcionID), extra: fixture);
  return (router: router, session: session);
}

Recepcion _package({bool retained = false}) => Recepcion(
      recepcionID: 'reception-1',
      fecha: '2026.08.11',
      producto: 'Libra',
      suplidor: 'Tienda',
      cantidadPaquetes: 1,
      contenido: 'Compra',
      enviadoPor: '',
      totalPeso: '1',
      totalVolumen: '',
      totalNeto: '100.00',
      estatus: retained ? 'Retenido' : 'Disponible',
      retenido: retained,
      disponible: !retained,
      paquetes: const [],
      fotoPaqueteSmallUrl: '',
      fotoPaqueteUrl: '',
      fotoFacturaUrl: '',
      fechaHora: '2026-08-11T12:00:00',
      progreso: 3,
      numeroRastreo: 'TRACK-1',
    );
