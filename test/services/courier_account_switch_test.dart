import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache/flutter_cache.dart' as cache;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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
  setupFirebaseCoreMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/firebase_messaging'),
      (_) async => <String, dynamic>{},
    );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GetIt.I.reset();
    GetIt.I.registerSingleton<AppInfo>(BmcargoAppInfo());
    GetIt.I.registerSingleton<BrandConfig>(loadTestBrand('bmcargo'));
  });

  tearDown(() => GetIt.I.reset());

  test('logging in with a second account remembers both across switches',
      () async {
    await http.runWithClient(() async {
      final service = CourierService();
      await service.getLoginResult('BM-001', 'password-one');
      expect((await service.getStoredAccounts()).map((a) => a.userAccount),
          ['BM-001']);

      await service.saveLoggedOutState();
      await service.getLoginResult('BM-002', 'password-two');
      expect(await cache.load('userAccount', ''), 'BM-002');
      expect((await service.getStoredAccounts()).map((a) => a.userAccount),
          ['BM-001', 'BM-002']);

      final reopenedService = CourierService();
      expect(await reopenedService.switchUserAccount('BM-001'), isTrue);
      expect(await cache.load('userAccount', ''), 'BM-001');
      expect(
          (await reopenedService.getStoredAccounts()).map((a) => a.userAccount),
          ['BM-001', 'BM-002']);
      expect(await reopenedService.switchUserAccount('BM-002'), isTrue);
      expect(await cache.load('userAccount', ''), 'BM-002');
      expect(
          (await reopenedService.getStoredAccounts())
              .every((a) => a.sessionId.isEmpty),
          isTrue);
      expect((await cache.load('storedAccounts', '')).toString(),
          isNot(contains('session-')));
    }, _loginClient);
  });

  test('signing in again updates remembered credentials without duplicates',
      () async {
    await http.runWithClient(() async {
      final service = CourierService();
      await service.getLoginResult('BM-001', 'password-one');
      await service.saveLoggedOutState();
      await service.getLoginResult('BM-001', 'updated-password');

      final accounts = await service.getStoredAccounts();
      expect(accounts, hasLength(1));
      expect(accounts.single.password, 'updated-password');
    }, _loginClient);
  });

  test('failed login does not remember an account or replace the session',
      () async {
    await http.runWithClient(() async {
      final service = CourierService();
      await service.getLoginResult('BM-001', 'password-one');
      final result = await service.getLoginResult('BM-002', 'invalid');

      expect(result.sessionId, isEmpty);
      expect(await cache.load('userAccount', ''), 'BM-001');
      expect((await service.getStoredAccounts()).map((a) => a.userAccount),
          ['BM-001']);
    }, _loginClient);
  });

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

http.Client _loginClient() => MockClient((request) async {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final account = body['userAccount'] as String;
      return http.Response(
        jsonEncode({
          'sessionId': body['password'] == 'invalid' ? '' : 'session-$account',
          'nombre': account == 'BM-001' ? 'Alicia' : 'Bruno',
          'email': 'example@example.com',
          'telefono': '',
          'sucursal': 'SDQ',
          'fotoPerfilUrl': '',
        }),
        200,
      );
    });

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
