import 'dart:async';
import 'dart:convert';

import 'package:event/event.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:icourier/apps/appinfo.dart';
import 'package:icourier/apps/bmcargo/appinfo_bmcargo.dart';
import 'package:icourier/navigation/app_runtime_host.dart';
import 'package:icourier/navigation/app_routes.dart';
import 'package:icourier/navigation/router_session.dart';
import 'package:icourier/noticas/emerging_news_coordinator.dart';
import 'package:icourier/noticas/emerging_news_dialog.dart';
import 'package:icourier/services/app_events.dart';
import 'package:icourier/services/courier_service.dart';
import 'package:icourier/services/model/empresa.dart';
import 'package:icourier/services/model/mensaje.dart';
import 'package:icourier/services/model/noticia.dart';
import 'package:icourier/theme/brand_config.dart';
import 'package:icourier/theme/brand_theme.dart';
import 'package:icourier/updates/app_update_coordinator.dart';
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

  testWidgets('expired session redirects from the app builder and shows notice',
      (tester) async {
    final preferences = await SharedPreferences.getInstance();
    final session = RouterSession(
      initiallyLoggedIn: true,
      loginChanges: GetIt.I<Event<LoginChanged>>(),
    );
    addTearDown(session.dispose);
    final router = GoRouter(
      refreshListenable: session,
      initialLocation: AppRoutes.available,
      routes: [
        GoRoute(
            path: AppRoutes.home,
            builder: (context, state) =>
                Scaffold(body: Text(session.isLoggedIn ? 'Inicio' : 'Login'))),
        GoRoute(
            path: AppRoutes.available,
            builder: (context, state) =>
                const Scaffold(body: Text('Paquetes'))),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(
      routerConfig: router,
      builder: (context, child) => AppRuntimeHost(
        preferences: preferences,
        router: router,
        navigatorKey: router.routerDelegate.navigatorKey,
        foregroundMessages: const Stream<RemoteMessage>.empty(),
        openedMessages: const Stream<RemoteMessage>.empty(),
        appUpdateCoordinator: _FakeAppUpdateCoordinator(),
        loadInitialMessage: () async => null,
        child: child!,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Paquetes'), findsOneWidget);
    expect(
      () => GetIt.I<Event<SessionExpired>>().broadcast(SessionExpired()),
      returnsNormally,
    );
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(session.isLoggedIn, isFalse);
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.home);
    expect(tester.takeException(), isNull);
  });

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
          appUpdateCoordinator: _FakeAppUpdateCoordinator(),
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

  testWidgets('daily popup shows once per opportunity up to N per day',
      (tester) async {
    final preferences = await SharedPreferences.getInstance();
    final dialog = find.byType(EmergingNewsDialog);
    await _pumpEmergingNewsHost(
      tester,
      coordinator: _dailyCoordinator(preferences, timesPerDay: 2),
    );

    expect(dialog, findsOneWidget);
    Navigator.of(tester.element(dialog)).pop(false);
    await tester.pumpAndSettle();
    expect(dialog, findsNothing, reason: 'closing must not reopen it');

    await _returnFromBackground(tester);
    expect(dialog, findsOneWidget);
    Navigator.of(tester.element(dialog)).pop(false);
    await tester.pumpAndSettle();

    await _returnFromBackground(tester);
    expect(dialog, findsNothing, reason: 'third opportunity exceeds N=2');
  });

  testWidgets('art that fails to load does not consume the daily quota',
      (tester) async {
    final preferences = await SharedPreferences.getInstance();
    await _pumpEmergingNewsHost(
      tester,
      coordinator: _dailyCoordinator(preferences, timesPerDay: 1),
      preloader: (context, imageUrl) async => null,
    );

    expect(find.byType(EmergingNewsDialog), findsNothing);
    expect(
      preferences
          .getString(SharedPreferencesEmergingNewsSeenStore.dailyStorageKey),
      isNull,
    );
  });

  testWidgets('shows emerging news once and opens its detail', (tester) async {
    final preferences = await SharedPreferences.getInstance();
    final config = GetIt.I<BrandConfig>();
    final seenStore = _MemoryEmergingNewsSeenStore();
    final company = Empresa.empty()
      ..options = jsonEncode({
        emergingNewsImageUrlOptionKey:
            'https://cdn.example.com/emergency-news.jpg',
        emergingNewsIdOptionKey: 'news-42',
      });
    final news = Noticia(
      registroId: 'news-42',
      empresa: 'company',
      fecha: DateTime(2026, 8, 29),
      titulo: 'Operación especial',
      resumen: 'Conoce los detalles de nuestro horario especial.',
      contenido: 'Contenido completo.',
      url: '',
      deleted: false,
    );
    final coordinator = EmergingNewsCoordinator(
      loadCompany: () async => company,
      loadNews: () async => [news],
      store: seenStore,
      courierId: 'courier',
    );
    late final GoRouter router;
    router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Inicio')),
        ),
        GoRoute(
          path: AppRoutes.newsDetailPattern,
          builder: (context, state) => Scaffold(
            body: Text('Detalle ${(state.extra! as Noticia).registroId}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        theme: BrandTheme.light(config),
        routerConfig: router,
        builder: (context, child) => AppRuntimeHost(
          preferences: preferences,
          navigatorKey: router.routerDelegate.navigatorKey,
          router: router,
          emergingNewsCoordinator: coordinator,
          emergingNewsImagePreloader: (context, imageUrl) async =>
              const Size(300, 600),
          foregroundMessages: const Stream<RemoteMessage>.empty(),
          openedMessages: const Stream<RemoteMessage>.empty(),
          appUpdateCoordinator: _FakeAppUpdateCoordinator(),
          loadInitialMessage: () async => null,
          child: child!,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Operación especial'), findsOneWidget);
    expect(
      seenStore.urls,
      contains('https://cdn.example.com/emergency-news.jpg'),
    );

    await tester.tap(find.text('Ver más'));
    await tester.pumpAndSettle();

    expect(find.text('Detalle news-42'), findsOneWidget);
  });

  testWidgets('prompts for an update and opens the platform store', (
    tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final config = GetIt.I<BrandConfig>();
    final navigatorKey = GlobalKey<NavigatorState>();
    final updateCoordinator = _FakeAppUpdateCoordinator(
      update: const AvailableAppUpdate(
        installedVersion: '2027.0.2',
        storeVersion: '2027.0.3',
        isRequired: false,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        theme: BrandTheme.light(config),
        builder: (context, child) => AppRuntimeHost(
          preferences: preferences,
          navigatorKey: navigatorKey,
          foregroundMessages: const Stream<RemoteMessage>.empty(),
          openedMessages: const Stream<RemoteMessage>.empty(),
          appUpdateCoordinator: updateCoordinator,
          loadInitialMessage: () async => null,
          child: child!,
        ),
        home: const Scaffold(body: Text('Inicio')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Actualización Disponible!'), findsOneWidget);
    expect(
      find.text(
        'Existe una nueva versión (2027.0.3) más reciente que su versión '
        'actual (2027.0.2), desea actualizar?',
      ),
      findsOneWidget,
    );
    expect(updateCoordinator.promptCount, 1);

    await tester.tap(find.text('Actualizar'));
    await tester.pumpAndSettle();

    expect(updateCoordinator.storeOpenCount, 1);
    expect(find.text('Actualización Disponible!'), findsNothing);
  });

  testWidgets('does not allow postponing a required update', (tester) async {
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
          appUpdateCoordinator: _FakeAppUpdateCoordinator(
            update: const AvailableAppUpdate(
              installedVersion: '2026.9.0',
              storeVersion: '2027.0.3',
              isRequired: true,
            ),
          ),
          loadInitialMessage: () async => null,
          child: child!,
        ),
        home: const Scaffold(body: Text('Inicio')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Actualizar'), findsOneWidget);
    expect(find.text('Quizás después'), findsNothing);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(find.text('Actualización Disponible!'), findsOneWidget);
  });
}

Future<void> _pumpEmergingNewsHost(
  WidgetTester tester, {
  required EmergingNewsCoordinator coordinator,
  EmergingNewsImagePreloader? preloader,
}) async {
  final preferences = await SharedPreferences.getInstance();
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: Text('Inicio')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      theme: BrandTheme.light(GetIt.I<BrandConfig>()),
      routerConfig: router,
      builder: (context, child) => AppRuntimeHost(
        preferences: preferences,
        navigatorKey: router.routerDelegate.navigatorKey,
        router: router,
        emergingNewsCoordinator: coordinator,
        emergingNewsImagePreloader:
            preloader ?? (context, imageUrl) async => const Size(300, 600),
        foregroundMessages: const Stream<RemoteMessage>.empty(),
        openedMessages: const Stream<RemoteMessage>.empty(),
        appUpdateCoordinator: _FakeAppUpdateCoordinator(),
        loadInitialMessage: () async => null,
        child: child!,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _returnFromBackground(WidgetTester tester) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pumpAndSettle();
}

EmergingNewsCoordinator _dailyCoordinator(
  SharedPreferences preferences, {
  required int timesPerDay,
}) =>
    EmergingNewsCoordinator(
      loadCompany: () async => Empresa.empty()
        ..options = jsonEncode({
          emergingNewsImageUrlOptionKey: 'https://cdn.example.com/daily.jpg',
          emergingNewsTimesPerDayOptionKey: timesPerDay,
        }),
      loadNews: () async => [],
      store: SharedPreferencesEmergingNewsSeenStore(preferences),
      courierId: 'courier',
      now: () => DateTime.utc(2026, 11, 7, 15),
    );

final class _FakeAppUpdateCoordinator implements AppUpdateCoordinator {
  _FakeAppUpdateCoordinator({this.update});

  final AvailableAppUpdate? update;
  int promptCount = 0;
  int storeOpenCount = 0;

  @override
  Future<AvailableAppUpdate?> findUpdate({bool refresh = false}) async =>
      update;

  @override
  Future<void> markPrompted() async {
    promptCount++;
  }

  @override
  Future<void> openStore() async {
    storeOpenCount++;
  }

  @override
  void dispose() {}
}

final class _MemoryEmergingNewsSeenStore implements EmergingNewsSeenStore {
  final Set<String> urls = {};

  @override
  Future<void> add(String imageUrl) async => urls.add(imageUrl);

  @override
  Future<bool> contains(String imageUrl) async => urls.contains(imageUrl);

  @override
  Future<int> shownCount(String campaignKey, String day) async => 0;

  @override
  Future<void> recordShown(String campaignKey, String day) async {}
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
