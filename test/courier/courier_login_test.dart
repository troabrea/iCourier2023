import 'package:event/event.dart' as event;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/apps/appinfo.dart';
import 'package:icourier/apps/bmcargo/appinfo_bmcargo.dart';
import 'package:icourier/courier/courier.dart';
import 'package:icourier/services/app_events.dart';
import 'package:icourier/services/courier_service.dart';
import 'package:icourier/services/model/empresa.dart';
import 'package:icourier/services/model/login_model.dart';
import 'package:icourier/theme/brand_config.dart';
import 'package:icourier/theme/brand_theme.dart';
import 'package:icourier/theme/brand_tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/brand_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _LoginService service;

  setUpAll(() async {
    initializeTestTranslations();
    await loadBrandFonts();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GetIt.I.reset();
    GetIt.I.registerSingleton<AppInfo>(BmcargoAppInfo());
    service = _LoginService();
    _registerDependencies(loadTestBrand('bmcargo'), service);
  });

  tearDown(() => GetIt.I.reset());

  testWidgets('keeps the form visible while credentials are verified', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    await tester.pumpWidget(_loginApp(GetIt.I<BrandConfig>()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('login-account-field')),
      'bm123',
    );
    await tester.enterText(
      find.byKey(const Key('login-password-field')),
      'secret',
    );
    await tester.tap(find.byKey(const Key('login-submit-button')));
    await tester.pump();

    expect(find.text('Verificando acceso…'), findsOneWidget);
    expect(find.byKey(const Key('login-account-field')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(service.loginRequests, 1);

    await tester.pump(service.loginDelay);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('login-error')), findsOneWidget);
    expect(
      find.text(
        'El código de cliente o la contraseña no coinciden. '
        'Revísalos e intenta nuevamente.',
      ),
      findsOneWidget,
    );
    final accountInput = find.descendant(
      of: find.byKey(const Key('login-account-field')),
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(accountInput).controller.text, 'bm123');
    expect(tester.takeException(), isNull);
  });

  testWidgets('validates required fields and toggles password visibility', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    await tester.pumpWidget(_loginApp(GetIt.I<BrandConfig>()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('login-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Requerido'), findsNWidgets(2));
    expect(service.loginRequests, 0);

    await tester.enterText(
      find.byKey(const Key('login-password-field')),
      'secret',
    );
    final passwordField = find.descendant(
      of: find.byKey(const Key('login-password-field')),
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(passwordField).obscureText, isTrue);

    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pump();

    expect(tester.widget<EditableText>(passwordField).obscureText, isFalse);
    expect(find.byTooltip('Ocultar contraseña'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('remains usable at 200% accessibility text', (tester) async {
    _setPhoneViewport(tester);
    await tester.pumpWidget(
      _loginApp(
        GetIt.I<BrandConfig>(),
        textScaler: const TextScaler.linear(2),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating labels stay legible over a bright brand outline', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    await GetIt.I.reset();
    GetIt.I.registerSingleton<AppInfo>(BmcargoAppInfo());
    final config = loadTestBrand('domex');
    _registerDependencies(config, service);
    await tester.pumpWidget(_loginApp(config));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('login-account-field')));
    await tester.pump(const Duration(milliseconds: 250));

    final field = find.descendant(
      of: find.byKey(const Key('login-account-field')),
      matching: find.byType(TextField),
    );
    final decoration = tester.widget<TextField>(field).decoration;
    final tokens = Theme.of(tester.element(field)).extension<BrandTokens>()!;

    expect(decoration?.floatingLabelStyle?.color, tokens.text);
    expect(decoration?.floatingLabelStyle?.color, isNot(tokens.primary));
    expect(_contrast(tokens.text, tokens.surface), greaterThanOrEqualTo(4.5));
    expect(tester.takeException(), isNull);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    await expectLater(
      find.byType(CourierPage),
      matchesGoldenFile('goldens/login_domex_focused.png'),
    );
  });

  testWidgets('matches the BM Cargo light login experience', (tester) async {
    _setPhoneViewport(tester);
    await tester.pumpWidget(_loginApp(GetIt.I<BrandConfig>()));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(CourierPage),
      matchesGoldenFile('goldens/login_bmcargo_light.png'),
    );
  });

  testWidgets('matches the Fixo Cargo dark login experience', (tester) async {
    _setPhoneViewport(tester);
    await GetIt.I.reset();
    GetIt.I.registerSingleton<AppInfo>(BmcargoAppInfo());
    final config = loadTestBrand('fixocargo');
    _registerDependencies(config, service);
    await tester.pumpWidget(
      _loginApp(config, brightness: Brightness.dark),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();

    await expectLater(
      find.byType(CourierPage),
      matchesGoldenFile('goldens/login_fixocargo_dark.png'),
    );
  });
}

void _registerDependencies(BrandConfig config, _LoginService service) {
  GetIt.I.registerSingleton<BrandConfig>(config);
  GetIt.I.registerSingleton<CourierService>(service);
  GetIt.I.registerSingleton<event.Event<LoginChanged>>(
    event.Event<LoginChanged>(),
  );
  GetIt.I.registerSingleton<event.Event<CourierRefreshRequested>>(
    event.Event<CourierRefreshRequested>(),
  );
  GetIt.I.registerSingleton<event.Event<LogoutRequested>>(
    event.Event<LogoutRequested>(),
  );
}

Widget _loginApp(
  BrandConfig config, {
  Brightness brightness = Brightness.light,
  TextScaler textScaler = TextScaler.noScaling,
}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('es'),
      theme: BrandTheme.light(config),
      darkTheme: BrandTheme.dark(config),
      themeMode:
          brightness == Brightness.light ? ThemeMode.light : ThemeMode.dark,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: const CourierPage(),
    );

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

LoginResult _invalidLogin() => LoginResult(
      sessionId: '',
      nombre: '',
      email: '',
      telefono: '',
      sucursal: '',
      fotoPerfilUrl: '',
    );

double _contrast(Color first, Color second) {
  final firstLuminance = first.computeLuminance() + 0.05;
  final secondLuminance = second.computeLuminance() + 0.05;
  return firstLuminance > secondLuminance
      ? firstLuminance / secondLuminance
      : secondLuminance / firstLuminance;
}

class _LoginService extends CourierService {
  int loginRequests = 0;
  final loginDelay = const Duration(milliseconds: 600);

  @override
  Future<Empresa> getEmpresa({
    bool ignoreCache = false,
    bool forceFirstTime = false,
    bool retryEmtpy = false,
  }) async =>
      Empresa.empty()..registerUrl = 'https://example.com/register';

  @override
  Future<LoginResult> getLoginResult(
    String usuario,
    String clave, {
    bool checkForNew = true,
  }) async {
    loginRequests++;
    await Future<void>.delayed(loginDelay);
    return _invalidLogin();
  }
}
