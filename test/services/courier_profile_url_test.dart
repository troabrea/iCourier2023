import 'dart:convert';

import 'package:flutter_cache/flutter_cache.dart' as cache;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/apps/appinfo.dart';
import 'package:icourier/apps/bmcargo/appinfo_bmcargo.dart';
import 'package:icourier/services/courier_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<AppInfo>(BmcargoAppInfo());
    SharedPreferences.setMockInitialValues({});
    await cache.write('userAccount', 'BM-096791');
    await cache.write('userPassword', 'secret');
  });

  tearDown(() => GetIt.I.reset());

  test('entrega las credenciales aunque no exista ProfileUrl', () async {
    final fields = await CourierService().getProfileUrl();

    expect(fields['UsuarioID'], 'BM-096791');
    expect(fields['UsuarioPW'], 'secret');
    expect(fields, isNot(contains('ActionURL')));
  });

  test('dirige la edición a la Azure Function con la identidad codificada',
      () async {
    final uri = await CourierService().getProfileEditUri();

    expect(uri, isNotNull);
    expect(uri!.scheme, 'https');
    expect(uri.host, 'icourier.barolit.net');
    expect(uri.pathSegments.first, 'EditProfile');
    expect(utf8.decode(base64Decode(uri.pathSegments[1])),
        BmcargoAppInfo().companyId);
    expect(utf8.decode(base64Decode(uri.pathSegments[2])), 'BM-096791');
    expect(utf8.decode(base64Decode(uri.pathSegments[3])), 'secret');
  });
}
