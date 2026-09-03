import 'dart:convert';

import 'package:event/event.dart' as event;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:icourier/apps/appinfo.dart';
import 'package:icourier/apps/bmcargo/appinfo_bmcargo.dart';
import 'package:icourier/asistente/assistant_action.dart';
import 'package:icourier/asistente/assistant_avatar.dart';
import 'package:icourier/design_system/brand_foundations.dart';
import 'package:icourier/design_system/core_components.dart';
import 'package:icourier/helpers/contact_action.dart';
import 'package:icourier/navigation/app_routes.dart';
import 'package:icourier/navigation/router_session.dart';
import 'package:icourier/services/app_events.dart';
import 'package:icourier/services/courier_service.dart';
import 'package:icourier/services/model/empresa.dart';
import 'package:icourier/services/model/assistant_settings.dart';
import 'package:icourier/services/model/login_model.dart';
import 'package:icourier/theme/brand_config.dart';
import 'package:icourier/theme/brand_theme.dart';

import '../helpers/brand_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late event.Event<LoginChanged> loginChanges;

  setUpAll(() async {
    initializeTestTranslations();
    await loadBrandFonts();
  });

  setUp(() async {
    await GetIt.I.reset();
    loginChanges = event.Event<LoginChanged>();
    GetIt.I.registerSingleton<AppInfo>(BmcargoAppInfo());
    GetIt.I.registerSingleton<BrandConfig>(loadTestBrand('bmcargo'));
    GetIt.I.registerSingleton<event.Event<LoginChanged>>(loginChanges);
    GetIt.I.registerSingleton<CourierService>(_ContactService());
  });

  tearDown(() => GetIt.I.reset());

  /// The accesses live on a real scaffold and router because their placement,
  /// destination and colours all come from that context.
  Future<String> pump(
    WidgetTester tester, {
    required bool signedIn,
    double? trailingGap,
  }) async {
    GetIt.I.registerSingleton<RouterSession>(
      RouterSession(initiallyLoggedIn: signedIn, loginChanges: loginChanges),
    );
    var location = '/';
    final config = GetIt.I<BrandConfig>();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            appBar: const ScreenHeader(
              title: 'Sucursales',
              trailing: BrandAssistantAction(),
            ),
            body: const SizedBox.shrink(),
            bottomNavigationBar: BrandTabBar(
              modules: config.navigation.tabs,
              index: 0,
              logoMark: config.assets.logoMark,
              onTap: (_) {},
              trailing: const BrandAssistantFloatingAction(),
              trailingGap: trailingGap,
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.assistant,
          builder: (context, state) {
            location = AppRoutes.assistant;
            return const Scaffold(body: Text('asistente'));
          },
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        locale: const Locale('es'),
        theme: BrandTheme.light(config),
      ),
    );
    await tester.pumpAndSettle();
    return location;
  }

  testWidgets('a signed-in customer gets the floating assistant, not WhatsApp',
      (tester) async {
    await pump(tester, signedIn: true);

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byType(AssistantAvatar), findsOneWidget);
    expect(
      tester
          .widget<AssistantAvatarEntrance>(
            find.byType(AssistantAvatarEntrance),
          )
          .rotate,
      isFalse,
    );
    expect(
      tester.widget<Hero>(find.byType(Hero)).tag,
      AssistantAvatar.heroTag,
    );
    expect(
      find.descendant(
        of: find.byType(AssistantAvatar),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is BrandGlyph && widget.asset == BrandIcons.assistant,
        ),
      ),
      findsOneWidget,
    );
    expect(find.byType(BrandContactAction), findsNothing);
    expect(find.byType(FaIcon), findsNothing);
    final fab = tester.getRect(find.byType(FloatingActionButton));
    final tabDock =
        tester.getRect(find.byKey(const ValueKey('brand-tab-dock')));
    expect(fab.left, greaterThan(tabDock.right));
    expect(fab.center.dy, closeTo(tabDock.center.dy, 0.5));

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('asistente'), findsOneWidget);
  });

  testWidgets('a narrower gap gives the dock the width back', (tester) async {
    await pump(tester, signedIn: true, trailingGap: 4);

    final dock = tester.getRect(find.byKey(const ValueKey('brand-tab-dock')));
    final trailing = tester.getRect(find.byType(FloatingActionButton));
    expect(trailing.left - dock.right, 4);
  });

  testWidgets('the side-by-side dock keeps usable tabs at compact width',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pump(tester, signedIn: true);

    final fab = tester.getRect(find.byType(FloatingActionButton));
    final tabDock =
        tester.getRect(find.byKey(const ValueKey('brand-tab-dock')));
    expect(fab.left, greaterThan(tabDock.right));
    for (var slot = 0; slot < 5; slot++) {
      final tab = tester.getRect(
        find.byKey(ValueKey('brand-tab-slot-$slot')),
      );
      expect(tab.width, greaterThanOrEqualTo(44));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('without a session the position falls back to WhatsApp',
      (tester) async {
    await pump(tester, signedIn: false);

    expect(find.byType(BrandContactAction), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(
      tester.widget<FaIcon>(find.byType(FaIcon)).icon,
      FontAwesomeIcons.whatsapp,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is BrandGlyph && widget.asset == BrandIcons.assistant,
      ),
      findsNothing,
    );
  });

  testWidgets('a courier without the module keeps WhatsApp, session or not',
      (tester) async {
    // The module is sold per courier, so the brand that never bought it must
    // not show the button at all — not even to a signed-in customer.
    await GetIt.I.unregister<CourierService>();
    GetIt.I.registerSingleton<CourierService>(
      _ContactService(assistant: false),
    );

    await pump(tester, signedIn: true);

    expect(find.byType(BrandContactAction), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(
      tester.widget<FaIcon>(find.byType(FaIcon)).icon,
      FontAwesomeIcons.whatsapp,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is BrandGlyph && widget.asset == BrandIcons.assistant,
      ),
      findsNothing,
    );
  });

  testWidgets('the module arriving after the first frame moves the access',
      (tester) async {
    await GetIt.I.unregister<CourierService>();
    final courier = _ContactService(assistant: false);
    GetIt.I.registerSingleton<CourierService>(courier);

    await pump(tester, signedIn: true);
    expect(find.byType(FaIcon), findsOneWidget);

    // What the company record landing looks like from here.
    courier.assistantEnabled.value = true;
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byType(BrandContactAction), findsNothing);
    expect(find.byType(FaIcon), findsNothing);
  });

  testWidgets('signing in swaps the fallback for the floating assistant',
      (tester) async {
    await pump(tester, signedIn: false);

    expect(find.byType(FaIcon), findsOneWidget);

    loginChanges.broadcast(LoginChanged(true, 'BM-096791', 'Temístocles'));
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byType(BrandContactAction), findsNothing);
  });

  testWidgets('new settings update the floating name and avatar',
      (tester) async {
    await pump(tester, signedIn: true);
    final courier = GetIt.I<CourierService>();
    const avatar =
        "<svg viewBox='0 0 24 24'><circle cx='12' cy='12' r='8'/></svg>";

    courier.assistantSettings.value = AssistantSettings.parse(
      jsonEncode({'Name': 'Mía', 'AvatarSvg': avatar}),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Mía'), findsOneWidget);
    expect(
      tester.widget<AssistantAvatar>(find.byType(AssistantAvatar)).avatarSvg,
      avatar,
    );
  });
}

class _ContactService extends CourierService {
  _ContactService({bool assistant = true}) {
    assistantEnabled.value = assistant;
  }

  @override
  Future<Empresa> getEmpresa({
    bool ignoreCache = false,
    bool forceFirstTime = false,
    bool retryEmtpy = false,
  }) async =>
      Empresa.empty();

  @override
  Future<UserProfile> getUserProfile() async => UserProfile(
        cuenta: 'BM-096791',
        nombre: 'Temístocles Roa',
        email: 'cliente@example.com',
        sucursal: 'DO-BVT',
        fotoPerfilUrl: '',
        direccionBuzon: '',
        buzones: const [],
        whatsappSucursal: '8095550100',
      );
}
