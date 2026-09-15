import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icourier/services/app_intent_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('icourier_app_intent_channel');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  Future<dynamic> send(String method, [Object? arguments]) async {
    final response = Completer<ByteData?>();
    await messenger.handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(MethodCall(method, arguments)),
      response.complete,
    );
    final data = await response.future;
    return data == null ? null : channel.codec.decodeEnvelope(data);
  }

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('readiness installs the receiver before native drains cold requests',
      () async {
    final opened = <String>[];
    final bridge = AppIntentBridge(openPickup: opened.add);
    addTearDown(bridge.dispose);
    Future<dynamic>? reply;
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'ready');
      reply = send('notificar_retiro', {'id': 'cold'});
      return null;
    });
    await bridge.start();
    expect(opened, ['cold']);
    expect(bridge.beginPresentation('cold'), isTrue);
    bridge.complete('cold');
    expect(await reply, isTrue);
  });

  test('waits through login and acknowledges only after confirmation closes',
      () async {
    final opened = <String>[];
    final bridge = AppIntentBridge(openPickup: opened.add);
    addTearDown(bridge.dispose);
    messenger.setMockMethodCallHandler(channel, (_) async => null);
    await bridge.start();
    var acknowledged = false;
    final reply = send('notificar_retiro', {'id': 'login'}).then((value) {
      acknowledged = true;
      return value;
    });
    await Future<void>.delayed(Duration.zero);
    expect(opened, ['login']);
    expect(acknowledged, isFalse);
    expect(bridge.beginPresentation('login'), isTrue);
    expect(bridge.beginPresentation('login'), isFalse);
    bridge.complete('login');
    expect(await reply, isTrue);
  });

  test('retries share completion and completed IDs never reopen the sheet',
      () async {
    final opened = <String>[];
    final bridge = AppIntentBridge(openPickup: opened.add);
    addTearDown(bridge.dispose);
    messenger.setMockMethodCallHandler(channel, (_) async => null);
    await bridge.start();
    final first = send('notificar_retiro', {'id': 'same'});
    final duplicate = send('notificar_retiro', {'id': 'same'});
    await Future<void>.delayed(Duration.zero);
    bridge.complete('same');
    expect(await first, isTrue);
    expect(await duplicate, isTrue);
    expect(await send('notificar_retiro', {'id': 'same'}), isTrue);
    expect(opened, ['same']);
    expect(bridge.beginPresentation('same'), isFalse);
  });

  test('rejects invalid requests and reports teardown without acknowledgment',
      () async {
    final bridge = AppIntentBridge(openPickup: (_) {});
    messenger.setMockMethodCallHandler(channel, (_) async => null);
    await bridge.start();
    await expectLater(
        send('notificar_retiro', []), throwsA(isA<PlatformException>()));
    final reply = send('notificar_retiro', {'id': 'pending'});
    await Future<void>.delayed(Duration.zero);
    bridge.dispose();
    expect(await reply, isFalse);
  });
}
