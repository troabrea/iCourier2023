import 'dart:convert';

import 'package:flutter/services.dart';

import 'widget_state_v1.dart';

abstract interface class WidgetStateStore {
  Future<void> write(
    WidgetStateV1 state, {
    required String appGroup,
    required String logoAsset,
    required WidgetRemoteSession remoteSession,
  });

  Future<void> clear({required String appGroup});
}

/// Credentials and routing required by native background widget refreshes.
final class WidgetRemoteSession {
  const WidgetRemoteSession({
    required this.sessionId,
    required this.companyId,
    required this.endpoint,
  });

  final String sessionId;
  final String companyId;
  final String endpoint;
}

final class MethodChannelWidgetStateStore implements WidgetStateStore {
  const MethodChannelWidgetStateStore();

  static const _channel = MethodChannel('icourier/widget_state');

  @override
  Future<void> write(
    WidgetStateV1 state, {
    required String appGroup,
    required String logoAsset,
    required WidgetRemoteSession remoteSession,
  }) async {
    final logoData = await rootBundle.load(logoAsset);
    final logoBytes = logoData.buffer.asUint8List(
      logoData.offsetInBytes,
      logoData.lengthInBytes,
    );
    try {
      await _channel.invokeMethod<void>('write', {
        'appGroup': appGroup,
        'key': WidgetStateV1.storageKey,
        'payload': jsonEncode(state.toJson()),
        'logoFile': WidgetStateV1.logoFileName,
        'logoBytes': logoBytes,
        'sessionId': remoteSession.sessionId,
        'companyId': remoteSession.companyId,
        'endpoint': remoteSession.endpoint,
      });
    } on MissingPluginException {
      // Widget extensions are unavailable in Flutter unit tests and desktop.
    }
  }

  @override
  Future<void> clear({required String appGroup}) async {
    try {
      await _channel.invokeMethod<void>('clear', {
        'appGroup': appGroup,
        'key': WidgetStateV1.storageKey,
      });
    } on MissingPluginException {
      // Widget extensions are unavailable in Flutter unit tests and desktop.
    }
  }
}
