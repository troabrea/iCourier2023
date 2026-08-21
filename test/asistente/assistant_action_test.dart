import 'package:event/event.dart' as event;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:icourier/apps/appinfo.dart';
import 'package:icourier/apps/bmcargo/appinfo_bmcargo.dart';
import 'package:icourier/asistente/assistant_action.dart';
import 'package:icourier/design_system/brand_foundations.dart';
import 'package:icourier/design_system/core_components.dart';
import 'package:icourier/helpers/contact_action.dart';
import 'package:icourier/navigation/app_routes.dart';
import 'package:icourier/navigation/router_session.dart';
import 'package:icourier/services/app_events.dart';
import 'package:icourier/services/courier_service.dart';
import 'package:icourier/services/model/empresa.dart';
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

  /// The action lives on a real header, inside a router, because both the tap
  /// destination and the foreground colour come from that context.
  Future<String> pump(WidgetTester tester, {required bool signedIn}) async {
    GetIt.I.registerSingleton<RouterSession>(
      RouterSession(initiallyLoggedIn: signedIn, loginChanges: loginChanges),
    );
    var location = '/';
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            appBar: ScreenHeader(
              title: 'Sucursales',
              trailing: BrandAssistantAction(),
            ),
            body: SizedBox.shrink(),
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
    final config = GetIt.I<BrandConfig>();
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

  testWidgets('a signed-in customer gets the assistant, not WhatsApp',
      (tester) async {
    await pump(tester, signedIn: true);

    expect(find.byType(BrandGlyph), findsOneWidget);
    expect(
      tester.widget<BrandGlyph>(find.byType(BrandGlyph)).asset,
      BrandIcons.assistant,
    );
    expect(find.byType(FaIcon), findsNothing);

    await tester.tap(find.byType(BrandGlyph));
    await tester.pumpAndSettle();

    expect(find.text('asistente'), findsOneWidget);
  });

  testWidgets('without a session the position falls back to WhatsApp',
      (tester) async {
    await pump(tester, signedIn: false);

    expect(find.byType(BrandContactAction), findsOneWidget);
    expect(
      tester.widget<FaIcon>(find.byType(FaIcon)).icon,
      FontAwesomeIcons.whatsapp,
    );
    expect(find.byType(BrandGlyph), findsNothing);
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
    expect(
      tester.widget<FaIcon>(find.byType(FaIcon)).icon,
      FontAwesomeIcons.whatsapp,
    );
    expect(find.byType(BrandGlyph), findsNothing);
  });

  testWidgets('the module arriving after the first frame corrects the button',
      (tester) async {
    await GetIt.I.unregister<CourierService>();
    final courier = _ContactService(assistant: false);
    GetIt.I.registerSingleton<CourierService>(courier);

    await pump(tester, signedIn: true);
    expect(find.byType(FaIcon), findsOneWidget);

    // What the company record landing looks like from here.
    courier.assistantEnabled.value = true;
    await tester.pumpAndSettle();

    expect(
      tester.widget<BrandGlyph>(find.byType(BrandGlyph)).asset,
      BrandIcons.assistant,
    );
  });

  testWidgets('signing in swaps the fallback for the assistant',
      (tester) async {
    await pump(tester, signedIn: false);

    expect(find.byType(FaIcon), findsOneWidget);

    loginChanges.broadcast(LoginChanged(true, 'BM-096791', 'Temístocles'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<BrandGlyph>(find.byType(BrandGlyph)).asset,
      BrandIcons.assistant,
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
