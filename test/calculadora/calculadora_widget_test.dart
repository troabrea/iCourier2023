import 'package:event/event.dart' as event;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/apps/appinfo.dart';
import 'package:icourier/apps/bmcargo/appinfo_bmcargo.dart';
import 'package:icourier/calculadora/calculadora.dart';
import 'package:icourier/services/app_events.dart';
import 'package:icourier/services/courier_service.dart';
import 'package:icourier/services/model/calculadora_model.dart';
import 'package:icourier/services/model/empresa.dart';
import 'package:icourier/services/model/login_model.dart';
import 'package:icourier/services/model/producto.dart';
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
    GetIt.I.registerSingleton<event.Event<LoginChanged>>(
      event.Event<LoginChanged>(),
    );
    GetIt.I.registerSingleton<CourierService>(_CalculatorService());
  });

  tearDown(() => GetIt.I.reset());

  testWidgets('calculator guides, quotes, and invalidates stale results',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final config = GetIt.I<BrandConfig>();

    await tester.pumpWidget(
      brandTestApp(config: config, child: const CalculadoraPage()),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Estime el costo de sus paquetes usando nuestra calculadora.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(CalculadoraPage),
      matchesGoldenFile('goldens/calculadora_inicial.png'),
    );

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '2,50');
    await tester.enterText(fields.at(1), '100');
    await tester.tap(find.text('Calcular Envío'));
    await tester.pumpAndSettle();

    expect(find.text('Total Estimado de Flete'), findsOneWidget);
    expect(find.text('RD\$28.00'), findsWidgets);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(CalculadoraPage),
      matchesGoldenFile('goldens/calculadora_resultado.png'),
    );

    await tester.enterText(fields.at(0), '3');
    await tester.pumpAndSettle();

    expect(find.text('Total Estimado de Flete'), findsNothing);
    expect(
      find.text('Estime el costo de sus paquetes usando nuestra calculadora.'),
      findsOneWidget,
    );
  });
}

class _CalculatorService extends CourierService {
  @override
  Future<Empresa> getEmpresa({
    bool ignoreCache = false,
    bool forceFirstTime = false,
    bool retryEmtpy = false,
  }) async {
    final company = Empresa.empty();
    company
      ..registroId = 'company'
      ..calculadoraProducto = 'AIR';
    return company;
  }

  @override
  Future<List<Producto>> getProductos(bool ignoreCache) async => [
        Producto(
          registroId: 'air',
          empresa: 'company',
          titulo: 'Aéreo estándar',
          codigo: 'AIR',
          orden: 1,
          deleted: false,
        ),
        Producto(
          registroId: 'sea',
          empresa: 'company',
          titulo: 'Marítimo',
          codigo: 'SEA',
          orden: 2,
          deleted: false,
        ),
      ];

  @override
  Future<UserProfile> getUserProfile() async => UserProfile(
        cuenta: '',
        nombre: '',
        email: '',
        sucursal: '',
        fotoPerfilUrl: '',
        direccionBuzon: '',
        buzones: const [],
      );

  @override
  Future<List<CalculadoraResponse>> getCalculadoraResult(
    double libras,
    double valor, {
    String producto = '',
  }) async =>
      [
        CalculadoraResponse(
          companiaId: 'company',
          oficinaId: '',
          transaccionId: '',
          transaccionDetalleId: '',
          productoId: producto,
          productoNombre: 'Flete aéreo',
          almacenId: '',
          cantidad: libras,
          unidadId: 'lb',
          piezas: 1,
          precio: 12,
          bruto: 24,
          pctDesc: 0,
          descuento: 0,
          pctImp: 16,
          impuesto: 4,
          neto: 28,
          monedaId: 'DOP',
          comentario: '',
        ),
      ];
}
