import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:event/event.dart' as event;
import 'package:icourier/adicional/adicional.dart';
import 'package:icourier/navigation/router_session.dart';
import 'package:icourier/services/app_events.dart';
import 'package:icourier/apps/appinfo.dart';
import 'package:icourier/apps/bmcargo/appinfo_bmcargo.dart';
import 'package:icourier/services/courier_service.dart';
import 'package:icourier/services/model/empresa.dart';
import 'package:icourier/services/model/login_model.dart';
import 'package:icourier/theme/brand_config.dart';

import '../helpers/brand_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    initializeTestTranslations();
    await loadBrandFonts();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/package_info'),
      (call) async => <String, Object>{
        'appName': 'iCourier',
        'packageName': 'com.test.icourier',
        'version': '2026.8.13',
        'buildNumber': '1',
        'buildSignature': '',
        'installerStore': '',
      },
    );
  });

  setUp(() {
    final config = loadTestBrand('bmcargo');
    GetIt.I.registerSingleton<AppInfo>(BmcargoAppInfo());
    GetIt.I.registerSingleton<BrandConfig>(config);
    GetIt.I.registerSingleton<CourierService>(_AdditionalService());
    // This screen is behind the session, so its header carries the assistant
    // rather than the WhatsApp fallback.
    GetIt.I.registerSingleton<event.Event<LoginChanged>>(
      event.Event<LoginChanged>(),
    );
    GetIt.I.registerSingleton<RouterSession>(
      RouterSession(
        initiallyLoggedIn: true,
        loginChanges: GetIt.I<event.Event<LoginChanged>>(),
      ),
    );
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets('restores the customer service and support actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      brandTestApp(
        config: GetIt.I<BrandConfig>(),
        child: const AdicionalInfoPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Asistente'), findsNothing);
    expect(find.text('Servicio al Cliente'), findsOneWidget);
    expect(find.text('Solicitar Soporte'), findsOneWidget);
    expect(find.byIcon(Icons.open_in_new_rounded), findsNWidgets(2));
    await expectLater(
      find.byType(AdicionalInfoPage),
      matchesGoldenFile('goldens/adicional_contacto.png'),
    );
  });
}

class _AdditionalService extends CourierService {
  @override
  Future<Empresa> getEmpresa({
    bool ignoreCache = false,
    bool forceFirstTime = false,
    bool retryEmtpy = false,
  }) async =>
      Empresa.empty()
        ..correoServicio = 'servicio@example.com'
        ..twitter = 'support.example.com'
        ..hasPreguntas = true
        ..mision = 'Nuestra misión.';

  @override
  Future<UserProfile> getUserProfile() async => UserProfile(
        cuenta: 'BM-096791',
        nombre: 'Temistocles Roa',
        email: 'cliente@example.com',
        sucursal: 'bella-vista',
        fotoPerfilUrl: '',
        direccionBuzon: 'Bella Vista',
        buzones: const [],
        nombreSucursal: 'Bella Vista',
      );
}
