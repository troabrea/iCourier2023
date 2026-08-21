import 'package:event/event.dart' as event;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/apps/appinfo.dart';
import 'package:icourier/apps/bmcargo/appinfo_bmcargo.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:icourier/courier/courier_dashboard.dart';
import 'package:icourier/design_system/brand_foundations.dart';
import 'package:icourier/services/app_events.dart';
import 'package:icourier/services/courier_service.dart';
import 'package:icourier/services/model/banner.dart';
import 'package:icourier/services/model/empresa.dart';
import 'package:icourier/services/model/login_model.dart';
import 'package:icourier/services/model/mensaje.dart';
import 'package:icourier/services/model/recepcion.dart';
import 'package:icourier/theme/brand_config.dart';

import '../helpers/brand_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    initializeTestTranslations();
    await loadBrandFonts();
  });

  setUp(() async {
    await GetIt.I.reset();
    final config = loadTestBrand('bmcargo');
    GetIt.I.registerSingleton<AppInfo>(BmcargoAppInfo());
    GetIt.I.registerSingleton<BrandConfig>(config);
    GetIt.I.registerSingleton<CourierService>(_DashboardService());
    GetIt.I.registerSingleton<event.Event<UnreadMessagesChanged>>(
      event.Event<UnreadMessagesChanged>(),
    );
  });

  tearDown(() => GetIt.I.reset());

  testWidgets('the header contact position now opens the assistant', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      brandTestApp(
        config: GetIt.I<BrandConfig>(),
        child: const CourierDashboard(),
      ),
    );
    await tester.pumpAndSettle();

    // The expanded panel and the collapsed bar carry the same cluster, so the
    // mark appears twice and WhatsApp appears nowhere.
    final marks = find.byWidgetPredicate(
      (widget) =>
          widget is BrandGlyph && widget.asset == BrandIcons.assistant,
    );
    expect(marks, findsNWidgets(2));
    expect(find.byType(FaIcon), findsNothing);
  });

  testWidgets('clears the notification badge when messages become read', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      brandTestApp(
        config: GetIt.I<BrandConfig>(),
        child: const CourierDashboard(),
      ),
    );
    await tester.pumpAndSettle();

    final messageButtons = find.ancestor(
      of: find.byIcon(Icons.notifications_none),
      matching: find.byType(GestureDetector),
    );
    expect(messageButtons, findsNWidgets(2));
    expect(
      find.descendant(of: messageButtons, matching: find.text('1')),
      findsNWidgets(2),
    );

    GetIt.I<event.Event<UnreadMessagesChanged>>()
        .broadcast(UnreadMessagesChanged(0));
    await tester.pump();

    expect(
      find.descendant(of: messageButtons, matching: find.text('1')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);

    final unreadChanges = GetIt.I<event.Event<UnreadMessagesChanged>>();
    expect(unreadChanges.subscriberCount, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(unreadChanges.subscriberCount, 0);
  });

  testWidgets('mantiene crear pre-alerta fuera de más acciones', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 520);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      brandTestApp(
        config: GetIt.I<BrandConfig>(),
        child: const CourierDashboard(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Crear Pre-Alerta'), findsOneWidget);
    expect(find.text('Más acciones'), findsOneWidget);

    await tester.ensureVisible(find.text('Más acciones'));
    await tester.tap(find.text('Más acciones'));
    await tester.pumpAndSettle();

    // La hoja sólo contiene las acciones secundarias.
    expect(find.text('Crear Pre-Alerta'), findsOneWidget);
    expect(find.text('Rastrear Paquete'), findsOneWidget);
  });
}

class _DashboardService extends CourierService {
  @override
  Future<Empresa> getEmpresa({
    bool ignoreCache = false,
    bool forceFirstTime = false,
    bool retryEmtpy = false,
  }) async =>
      Empresa.empty()..hasAssistantModule = true;

  @override
  Future<List<BannerImage>> getBanners({
    bool hideIfLogged = false,
    bool ignoreCache = false,
  }) async =>
      [];

  @override
  Future<List<Mensaje>> getMensajes({bool ignoreCache = false}) async => [
        Mensaje(
          registroId: 'message-1',
          empresa: 'demo',
          fecha: DateTime(2026, 8, 13),
          titulo: 'Mensaje pendiente',
          contenido: 'Contenido',
          deleted: false,
          read: false,
        ),
      ];

  @override
  Future<List<Recepcion>> getRecepciones(bool forceRefresh) async => [];

  @override
  Future<UserProfile> getUserProfile() async => UserProfile(
        cuenta: 'BM-123',
        nombre: 'Ada Lovelace',
        email: 'ada@example.com',
        sucursal: 'Principal',
        fotoPerfilUrl: '',
        direccionBuzon: 'Suite 123',
        buzones: const [],
      );
}
