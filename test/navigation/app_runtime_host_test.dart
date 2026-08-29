import 'dart:async';

import 'package:event/event.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/apps/appinfo.dart';
import 'package:icourier/apps/bmcargo/appinfo_bmcargo.dart';
import 'package:icourier/navigation/app_runtime_host.dart';
import 'package:icourier/services/app_events.dart';
import 'package:icourier/services/courier_service.dart';
import 'package:icourier/services/model/empresa.dart';
import 'package:icourier/services/model/mensaje.dart';
import 'package:icourier/theme/brand_config.dart';
import 'package:icourier/theme/brand_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/brand_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initializeTestTranslations);

  setUp(() async {
    await GetIt.I.reset();
    SharedPreferences.setMockInitialValues({});
    GetIt.I.registerSingleton<AppInfo>(BmcargoAppInfo());
    GetIt.I.registerSingleton<BrandConfig>(loadTestBrand('bmcargo'));
    GetIt.I.registerSingleton<CourierService>(_RuntimeCourierService());
    GetIt.I.registerSingleton<Event<SessionExpired>>(
      Event<SessionExpired>(),
    );
    GetIt.I.registerSingleton<Event<LoginChanged>>(Event<LoginChanged>());
  });

  tearDown(() => GetIt.I.reset());

  testWidgets('shows an initial push after the application is mounted', (
    tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final config = GetIt.I<BrandConfig>();
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        theme: BrandTheme.light(config),
        builder: (context, child) => AppRuntimeHost(
          preferences: preferences,
          navigatorKey: navigatorKey,
          foregroundMessages: const Stream<RemoteMessage>.empty(),
          openedMessages: const Stream<RemoteMessage>.empty(),
          loadInitialMessage: () async => const RemoteMessage(
            data: {
              'title': 'Paquete disponible',
              'body': 'Ya puedes retirar tu paquete.',
            },
          ),
          child: child!,
        ),
        home: const Scaffold(body: Text('Inicio')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Paquete disponible'), findsOneWidget);
    expect(find.text('Ya puedes retirar tu paquete.'), findsOneWidget);
    expect(
      (GetIt.I<CourierService>() as _RuntimeCourierService)
          .forcedMessageRefreshes,
      1,
    );

    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();

    expect(find.text('Paquete disponible'), findsNothing);
  });
}

final class _RuntimeCourierService extends CourierService {
  int forcedMessageRefreshes = 0;

  @override
  Future<Empresa> getEmpresa({
    bool ignoreCache = false,
    bool forceFirstTime = false,
    bool retryEmtpy = false,
  }) =>
      Future<Empresa>.error(Exception('No company in this test'));

  @override
  Future<List<Mensaje>> getMensajes({bool ignoreCache = false}) async {
    if (ignoreCache) {
      forcedMessageRefreshes++;
    }
    return [];
  }
}
