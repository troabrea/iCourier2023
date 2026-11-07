import 'package:event/event.dart';
import 'package:flutter_cache/flutter_cache.dart' as cache;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/apps/appinfo.dart';
import 'package:icourier/apps/bmcargo/appinfo_bmcargo.dart';
import 'package:icourier/services/app_events.dart';
import 'package:icourier/services/courier_service.dart';
import 'package:icourier/services/model/login_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
    SharedPreferences.setMockInitialValues({});
    GetIt.I.registerSingleton<AppInfo>(BmcargoAppInfo());
    GetIt.I.registerSingleton<Event<LogoutRequested>>(Event<LogoutRequested>());
    GetIt.I.registerSingleton<Event<SessionExpired>>(Event<SessionExpired>());
    await cache.write('sessionId', 'old-session');
    await cache.write('userAccount', 'BM-001');
    await cache.write('userPassword', 'old-password');
    await cache.write('userSucursal', 'SDQ');
  });
  tearDown(() => GetIt.I.reset());

  test('rejected password clears session before notifying and stops request',
      () async {
    final service = _RejectedSessionService();
    var expirations = 0;
    GetIt.I<Event<SessionExpired>>().subscribe((_) {
      expect(service.cleared, isTrue);
      expirations++;
    });

    await expectLater(service.getPrealertas(), throwsA(isA<Exception>()));

    expect(service.cleared, isTrue);
    expect(expirations, 1);
    expect(await cache.load('sessionId', ''), isEmpty);
  });
}

final class _RejectedSessionService extends CourierService {
  bool cleared = false;

  @override
  Future<LoginResult> getLoginResult(String usuario, String clave,
      {bool checkForNew = true}) async {
    expect(usuario, 'BM-001');
    expect(clave, 'old-password');
    expect(checkForNew, isFalse);
    return LoginResult(
        sessionId: '',
        nombre: '',
        email: '',
        telefono: '',
        sucursal: '',
        fotoPerfilUrl: '');
  }

  @override
  Future<void> saveLoggedOutState() async {
    await cache.write('sessionId', '');
    await cache.write('userAccount', '');
    await cache.write('userPassword', '');
    cleared = true;
  }
}
