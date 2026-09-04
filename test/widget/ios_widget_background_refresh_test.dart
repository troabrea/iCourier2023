import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final appDelegate = File('ios/Runner/AppDelegate.swift').readAsStringSync();
  final runnerInfo = File('ios/Runner/Info.plist').readAsStringSync();
  final widget =
      File('ios/ICourierWidget/ICourierWidget.swift').readAsStringSync();

  test('remote notifications request an immediate iOS widget refresh', () {
    expect(appDelegate, contains('didReceiveRemoteNotification'));
    expect(appDelegate, contains('widget_refresh_requested_at'));
    expect(appDelegate, contains('reloadTimelines(ofKind: "ICourierWidget")'));
    expect(runnerInfo, contains('<key>AppGroupIdentifier</key>'));
  });

  test('a push-triggered refresh bypasses the periodic refresh interval', () {
    expect(widget, contains('widget_refresh_requested_at'));
    expect(widget, contains('requestedAt > generatedAt'));
  });
}
