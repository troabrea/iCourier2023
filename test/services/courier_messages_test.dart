import 'dart:convert';

import 'package:event/event.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache/flutter_cache.dart' as cache;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/apps/appinfo.dart';
import 'package:icourier/apps/tupaq/appinfo_tupaq.dart';
import 'package:icourier/services/app_events.dart';
import 'package:icourier/services/courier_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockDecodedMessageHandler<Object?>(
      const BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.firebase_analytics_platform_interface.FirebaseAnalyticsHostApi.logEvent',
        StandardMessageCodec(),
      ),
      (_) async => <Object?>[null],
    );
  });

  setUp(() async {
    await GetIt.I.reset();
    SharedPreferences.setMockInitialValues({});
    GetIt.I.registerSingleton<AppInfo>(TupaqAppInfo());
    GetIt.I.registerSingleton<Event<UnreadMessagesChanged>>(
      Event<UnreadMessagesChanged>(),
    );
  });

  tearDown(() => GetIt.I.reset());

  test('excludes announcements older than 30 days', () async {
    await cache.write(
        'mensajes',
        jsonEncode([
          {
            ..._announcement,
            'createdAt': DateTime.now()
                .toUtc()
                .subtract(const Duration(days: 31))
                .toIso8601String(),
          },
        ]));
    final messages = await CourierService().getMensajes();
    expect(messages, isEmpty);
  });

  test('recent announcements survive the same response path', () async {
    await cache.write(
        'mensajes',
        jsonEncode([
          {
            ..._announcement,
            'createdAt': DateTime.now()
                .toUtc()
                .subtract(const Duration(days: 29))
                .toIso8601String()
          },
        ]));
    final messages = await CourierService().getMensajes();
    expect(messages.single.registroId, _announcement['registroID']);
  });

  test('excludes deleted messages and counts only unread active messages',
      () async {
    final recent = {
      ..._announcement,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
    await cache.write(
        'mensajes',
        jsonEncode([
          recent,
          {...recent, 'registroID': 'deleted', 'deleted': true},
          {...recent, 'registroID': 'already-read'},
        ]));
    await cache.write('messages_leidos', 'already-read');
    int? unread;
    GetIt.I<Event<UnreadMessagesChanged>>().subscribe(
      (change) => unread = change?.unreadCount,
    );
    final service = CourierService();
    final messages = await service.getMensajes();
    expect(messages.map((message) => message.registroId), [
      _announcement['registroID'],
      'already-read',
    ]);
    expect(messages.last.read, isTrue);
    expect(unread, 1);

    await service.setMessagesRead([messages.first.registroId]);
    expect(unread, 0);
    expect(
        (await service.getMensajes()).every((message) => message.read), isTrue);
  });
}

const _announcement = {
  'registroID': 'ac4d6609-4d0c-41dd-8ec0-80db22708dd8',
  'empresa': '8894b096-f666-4787-9a86-69423090721b',
  'titulo': '🚨Abiertos los Domingos📦',
  'contenido':
      '🆕Ahora en LA CASTELLANA también abrimos los domingos 📦 de 9Am-12Pm. \n',
  'codigoSucursal': 'DO.PAR',
  'envioNotificacion': 3.0,
  'mensajes': 0,
  'deleted': false,
  'createdAt': '2026-06-18T22:39:56.993+00:00',
};
