import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final manifest =
      File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
  final receiver = File(
    'android/app/src/main/kotlin/com/barolit/icourier/widget/'
    'WidgetRefreshPushReceiver.kt',
  );
  final scheduler = File(
    'android/app/src/main/kotlin/com/barolit/icourier/widget/'
    'WidgetRefreshScheduler.kt',
  ).readAsStringSync();
  final worker = File(
    'android/app/src/main/kotlin/com/barolit/icourier/widget/'
    'WidgetRemoteRefreshWorker.kt',
  ).readAsStringSync();

  test('FCM delivery requests an immediate Android widget refresh', () {
    expect(manifest, contains('.widget.WidgetRefreshPushReceiver'));
    expect(manifest, contains('com.google.android.c2dm.intent.RECEIVE'));
    expect(receiver.existsSync(), isTrue);
    expect(
      receiver.readAsStringSync(),
      contains('WidgetRefreshScheduler.requestImmediate(context)'),
    );
    expect(scheduler, contains('OneTimeWorkRequestBuilder'));
    expect(scheduler, contains('setExpedited'));
  });

  test('the immediate work tells the worker to bypass freshness', () {
    expect(scheduler, contains('FORCE_REFRESH_INPUT_KEY'));
    expect(worker, contains('forceRefresh'));
  });
}
