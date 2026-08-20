import 'dart:async';

import 'package:event/event.dart' as event;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/apps/appinfo.dart';
import 'package:icourier/apps/bmcargo/appinfo_bmcargo.dart';
import 'package:icourier/design_system/content_components.dart';
import 'package:icourier/helpers/social_media_links.dart';
import 'package:icourier/servicios/servicios.dart';
import 'package:icourier/services/app_events.dart';
import 'package:icourier/services/courier_service.dart';
import 'package:icourier/services/model/banner.dart';
import 'package:icourier/services/model/empresa.dart';
import 'package:icourier/services/model/login_model.dart';
import 'package:icourier/services/model/servicio.dart';
import 'package:icourier/theme/brand_config.dart';

import '../helpers/brand_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _ServicesService service;

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
    service = _ServicesService();
    GetIt.I.registerSingleton<CourierService>(service);
  });

  tearDown(() => GetIt.I.reset());

  testWidgets('tab root stays quiet and owns the banners', (tester) async {
    _setPhoneViewport(tester);

    await tester.pumpWidget(
      brandTestApp(
        config: GetIt.I<BrandConfig>(),
        child: const ServiciosPage(isTabRoot: true),
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
      lessThan(tester.getTopLeft(find.text('Casillero internacional')).dy),
    );
    expect(find.text('Elige el servicio que necesitas.'), findsNothing);
    expect(find.text('2 servicios disponibles'), findsNothing);
    expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
    expect(
      find.text('Recibe tus compras y consulta cada etapa del traslado.'),
      findsNothing,
    );
    expect(find.text('Ver detalle'), findsNothing);
    expect(find.byIcon(Icons.open_in_new_rounded), findsNothing);

    await tester.tap(find.text('Casillero internacional'));
    await tester.pumpAndSettle();

    expect(
      find.text('Recibe tus compras y consulta cada etapa del traslado.'),
      findsOneWidget,
    );
    expect(find.text('Ver detalle'), findsOneWidget);
    expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);
    expect(service.bannerRequests, 1);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(ServiciosPage),
      matchesGoldenFile('goldens/servicios_tab.png'),
    );
  });

  testWidgets('stacked services add context but do not request banners',
      (tester) async {
    _setPhoneViewport(tester);

    await tester.pumpWidget(
      brandTestApp(
        config: GetIt.I<BrandConfig>(),
        child: const ServiciosPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BannerCarousel), findsNothing);
    expect(find.byType(SocialMediaLinks), findsNothing);
    expect(find.text('Elige el servicio que necesitas.'), findsOneWidget);
    expect(find.text('2 servicios disponibles'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    expect(find.text('Ver detalle'), findsNothing);
    expect(service.bannerRequests, 0);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(ServiciosPage),
      matchesGoldenFile('goldens/servicios_submenu.png'),
    );
  });

  testWidgets('pull-to-refresh keeps services visible', (tester) async {
    await tester.pumpWidget(
      brandTestApp(
        config: GetIt.I<BrandConfig>(),
        child: const ServiciosPage(),
      ),
    );
    await tester.pumpAndSettle();

    service.refresh = Completer<List<Servicio>>();
    final refresh = tester
        .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
        .show();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Casillero internacional'), findsOneWidget);

    service.refresh!.complete(service.items);
    await tester.pumpAndSettle();
    await refresh;

    expect(service.serviceRequests, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty state stays refreshable', (tester) async {
    service.items = [];
    await tester.pumpWidget(
      brandTestApp(
        config: GetIt.I<BrandConfig>(),
        child: const ServiciosPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
        find.text('No hay servicios disponibles por ahora.'), findsOneWidget);
    expect(find.text('Actualizar'), findsOneWidget);
    expect(find.text('Elige el servicio que necesitas.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('service cards tolerate 200% accessibility text', (tester) async {
    await tester.pumpWidget(
      brandTestApp(
        config: GetIt.I<BrandConfig>(),
        textScaler: const TextScaler.linear(2),
        child: const ServiciosPage(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Casillero internacional'));
    await tester.pumpAndSettle();

    expect(find.text('Casillero internacional'), findsOneWidget);
    expect(find.text('Carga comercial'), findsOneWidget);
    expect(find.text('Ver detalle'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('details and external action follow progressive disclosure', (
    tester,
  ) async {
    await tester.pumpWidget(
      brandTestApp(
        config: GetIt.I<BrandConfig>(),
        child: const ServiciosPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ver detalle'), findsNothing);

    await tester.tap(find.text('Carga comercial'));
    await tester.pumpAndSettle();
    expect(
      find.text('Conoce las opciones disponibles para tus envíos comerciales.'),
      findsOneWidget,
    );
    expect(find.text('Ver detalle'), findsNothing);

    await tester.tap(find.text('Carga comercial'));
    await tester.pumpAndSettle();
    expect(
      find.text('Conoce las opciones disponibles para tus envíos comerciales.'),
      findsNothing,
    );

    await tester.tap(find.text('Casillero internacional'));
    await tester.pumpAndSettle();
    expect(find.text('Ver detalle'), findsOneWidget);
    expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class _ServicesService extends CourierService {
  int bannerRequests = 0;
  int serviceRequests = 0;
  Completer<List<Servicio>>? refresh;
  List<Servicio> items = [
    Servicio(
      registroId: 'service-1',
      empresa: 'demo',
      titulo: 'Casillero internacional',
      resumen: 'Recibe tus compras y consulta cada etapa del traslado.',
      detailsUrl: 'https://example.com/casillero',
      orden: 1,
      deleted: false,
    ),
    Servicio(
      registroId: 'service-2',
      empresa: 'demo',
      titulo: 'Carga comercial',
      resumen: 'Conoce las opciones disponibles para tus envíos comerciales.',
      detailsUrl: '',
      orden: 2,
      deleted: false,
    ),
  ];

  @override
  Future<List<Servicio>> getServicios(bool ignoreCache) {
    serviceRequests++;
    if (ignoreCache && refresh != null) {
      return refresh!.future;
    }
    return Future.value(items);
  }

  @override
  Future<List<BannerImage>> getBanners({
    bool hideIfLogged = false,
    bool ignoreCache = false,
  }) async {
    bannerRequests++;
    return [
      BannerImage(
        registroId: 'banner-1',
        empresa: 'demo',
        imagenId: '',
        descripcion: 'Servicios para tus envíos',
        url: '',
        deleted: false,
      ),
    ];
  }

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
