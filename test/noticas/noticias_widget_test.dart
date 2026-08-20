import 'dart:async';

import 'package:event/event.dart' as event;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/apps/appinfo.dart';
import 'package:icourier/apps/bmcargo/appinfo_bmcargo.dart';
import 'package:icourier/design_system/brand_states.dart';
import 'package:icourier/design_system/content_components.dart';
import 'package:icourier/helpers/social_media_links.dart';
import 'package:icourier/noticas/noticias.dart';
import 'package:icourier/services/app_events.dart';
import 'package:icourier/services/courier_service.dart';
import 'package:icourier/services/model/banner.dart';
import 'package:icourier/services/model/empresa.dart';
import 'package:icourier/services/model/login_model.dart';
import 'package:icourier/services/model/noticia.dart';
import 'package:icourier/theme/brand_config.dart';

import '../helpers/brand_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _NewsService service;

  setUpAll(() async {
    initializeTestTranslations();
    await loadBrandFonts();
  });

  setUp(() async {
    await GetIt.I.reset();
    final config = loadTestBrand('bmcargo');
    GetIt.I.registerSingleton<AppInfo>(BmcargoAppInfo());
    GetIt.I.registerSingleton<BrandConfig>(config);
    GetIt.I.registerSingleton<event.Event<LoginChanged>>(
      event.Event<LoginChanged>(),
    );
    service = _NewsService();
    GetIt.I.registerSingleton<CourierService>(service);
  });

  tearDown(() => GetIt.I.reset());

  testWidgets('tab root places social links between banners and news', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      brandTestApp(
        config: GetIt.I<BrandConfig>(),
        child: const NoticiasPage(isTabRoot: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BannerCarousel), findsOneWidget);
    expect(find.byType(SocialMediaLinks), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(SocialMediaLinks)).dy,
      greaterThan(tester.getBottomLeft(find.byType(BannerCarousel)).dy),
    );
    expect(
      tester.getBottomLeft(find.byType(SocialMediaLinks)).dy,
      lessThan(
          tester.getTopLeft(find.text('Nueva ruta directa a Santiago')).dy),
    );
    await expectLater(
      find.byType(NoticiasPage),
      matchesGoldenFile('goldens/noticias_tab_social.png'),
    );
  });

  testWidgets('news stays readable while pull-to-refresh completes',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      brandTestApp(
        config: GetIt.I<BrandConfig>(),
        child: const NoticiasPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nueva ruta directa a Santiago'), findsOneWidget);
    expect(find.byType(SocialMediaLinks), findsNothing);
    expect(
        find.text('Contenido editorial sin resumen dedicado.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(NoticiasPage),
      matchesGoldenFile('goldens/noticias_lista.png'),
    );

    service.refresh = Completer<List<Noticia>>();
    final refresh = tester
        .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
        .show();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(BrandSkeleton), findsNothing);
    expect(find.text('Nueva ruta directa a Santiago'), findsOneWidget);

    service.refresh!.complete(service.items);
    await tester.pumpAndSettle();
    await refresh;

    expect(service.newsRequests, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty news remains refreshable and explains the state',
      (tester) async {
    service.items = [];
    await tester.pumpWidget(
      brandTestApp(
        config: GetIt.I<BrandConfig>(),
        child: const NoticiasPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No hay noticias publicadas por ahora.'), findsOneWidget);
    expect(find.text('Actualizar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('news cards tolerate 200% accessibility text', (tester) async {
    await tester.pumpWidget(
      brandTestApp(
        config: GetIt.I<BrandConfig>(),
        textScaler: const TextScaler.linear(2),
        child: const NoticiasPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nueva ruta directa a Santiago'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _NewsService extends CourierService {
  int newsRequests = 0;
  Completer<List<Noticia>>? refresh;
  List<Noticia> items = [
    Noticia(
      registroId: 'story-1',
      empresa: 'demo',
      fecha: DateTime(2026, 8, 12),
      titulo: 'Nueva ruta directa a Santiago',
      resumen: 'Tus paquetes ahora tienen una opción adicional de traslado.',
      contenido: '',
      url: '',
      deleted: false,
    ),
    Noticia(
      registroId: 'story-2',
      empresa: 'demo',
      fecha: DateTime(2026, 8, 8),
      titulo: 'Horario especial de nuestras sucursales',
      resumen: '',
      contenido: '<p>Contenido editorial sin resumen dedicado.</p>',
      url: 'https://example.com/horarios',
      deleted: false,
    ),
  ];

  @override
  Future<List<Noticia>> getNoticias(bool ignoreCache) {
    newsRequests++;
    if (ignoreCache && refresh != null) {
      return refresh!.future;
    }
    return Future.value(items);
  }

  @override
  Future<List<BannerImage>> getBanners({
    bool hideIfLogged = false,
    bool ignoreCache = false,
  }) async =>
      [
        BannerImage(
          registroId: 'banner-1',
          empresa: 'demo',
          imagenId: '',
          descripcion: 'Noticias y novedades',
          url: '',
          deleted: false,
        ),
      ];

  @override
  Future<Empresa> getEmpresa({
    bool ignoreCache = false,
    bool forceFirstTime = false,
    bool retryEmtpy = false,
  }) async =>
      Empresa.empty()
        ..paginaWeb = 'https://example.com'
        ..correoVentas = 'ventas@example.com'
        ..instagram = 'example'
        ..facebook = 'example';

  @override
  Future<UserProfile> getUserProfile() async => UserProfile(
        cuenta: '',
        nombre: '',
        email: '',
        sucursal: '',
        fotoPerfilUrl: '',
        direccionBuzon: '',
        buzones: const [],
        emailSucursal: 'sucursal@example.com',
      );
}
