import 'dart:convert';

import 'package:flutter_cache/flutter_cache.dart' as cache;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/apps/appinfo.dart';
import 'package:icourier/apps/bmcargo/appinfo_bmcargo.dart';
import 'package:icourier/services/courier_service.dart';
import 'package:icourier/services/model/login_model.dart';
import 'package:icourier/services/model/recepcion.dart';
import 'package:icourier/theme/brand_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/brand_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GetIt.I.reset();
    GetIt.I.registerSingleton<AppInfo>(BmcargoAppInfo());
    GetIt.I.registerSingleton<BrandConfig>(loadTestBrand('bmcargo'));
  });

  tearDown(() => GetIt.I.reset());

  test('switching accounts discards packages cached by the prior session',
      () async {
    final service = _AccountSwitchService();
    await cache.write('recepciones', 'packages-from-account-one');

    final switched = await service.switchUserAccount('BM-002');

    expect(switched, isTrue);
    expect(await cache.load('recepciones', ''), isEmpty);
    expect(await cache.load('userAccount', ''), 'BM-002');
    expect(await cache.load('sessionId', ''), 'session-two');
  });

  test('package cache is isolated by account identity', () async {
    final service = _AccountSwitchService();
    await cache.write('sessionId', 'session-two');
    await cache.write('userAccount', 'BM-002');
    await cache.write(
      'recepciones:BM-001',
      jsonEncode([_reception('package-one').toJson()]),
    );
    await cache.write(
      'recepciones:BM-002',
      jsonEncode([_reception('package-two').toJson()]),
    );
    await cache.write(
      'recepciones',
      jsonEncode([_reception('legacy-package-one').toJson()]),
    );

    final packages = await service.getRecepciones(false);

    expect(packages.map((package) => package.recepcionID), ['package-two']);
  });

  test('stored accounts do not retain obsolete session tokens', () async {
    await cache.write(
      'storedAccounts',
      jsonEncode([
        {
          'sessionId': 'obsolete-session-one',
          'nombre': 'Alicia',
          'userAccount': 'BM-001',
          'password': 'password-one',
        },
      ]),
    );

    final accounts = await CourierService().getStoredAccounts();

    expect(accounts.single.sessionId, isEmpty);
    expect(
      (await cache.load('storedAccounts', '')).toString(),
      isNot(contains('obsolete-session-one')),
    );
  });
}

final class _AccountSwitchService extends CourierService {
  @override
  Future<List<UserAccount>> getStoredAccounts() async => [
        UserAccount(
          sessionId: 'stored-session-two',
          nombre: 'Bruno',
          userAccount: 'BM-002',
          password: 'password-two',
        ),
      ];

  @override
  Future<LoginResult> getLoginResult(
    String usuario,
    String clave, {
    bool checkForNew = true,
  }) async =>
      LoginResult(
        sessionId: 'session-two',
        nombre: 'Bruno',
        email: 'bruno@example.com',
        telefono: '',
        sucursal: 'SDQ',
        fotoPerfilUrl: '',
      );

  @override
  Future<void> saveLoggedOutState() async {
    await cache.write('sessionId', '');
    await cache.write('userAccount', '');
  }

  @override
  Future<void> saveLoggedInState(
    LoginResult loginResult,
    String userAccount,
    String userPassword,
  ) async {
    await cache.write('sessionId', loginResult.sessionId);
    await cache.write('userAccount', userAccount);
  }
}

Recepcion _reception(String id) => Recepcion(
      recepcionID: id,
      fecha: '2026.08.28',
      producto: 'Libra',
      suplidor: 'Proveedor',
      cantidadPaquetes: 1,
      contenido: id,
      enviadoPor: '',
      totalPeso: '1',
      totalVolumen: '',
      totalNeto: '10.00',
      estatus: 'Embarcado',
      retenido: false,
      disponible: false,
      paquetes: const [],
      fotoPaqueteSmallUrl: '',
      fotoPaqueteUrl: '',
      fotoFacturaUrl: '',
      fechaHora: '2026-08-28T12:00:00',
      progreso: 2,
      numeroRastreo: id,
    );
