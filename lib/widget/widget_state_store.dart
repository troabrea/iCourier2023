import 'dart:convert';

import 'package:flutter/services.dart';

import 'widget_state_v1.dart';

abstract interface class WidgetStateStore {
  Future<void> write(WidgetStateV1 state, {required String appGroup});

  Future<void> clear({required String appGroup});
}

final class MethodChannelWidgetStateStore implements WidgetStateStore {
  const MethodChannelWidgetStateStore();

  static const _channel = MethodChannel('icourier/widget_state');

  @override
  Future<void> write(WidgetStateV1 state, {required String appGroup}) async {
    try {
      await _channel.invokeMethod<void>('write', {
        'appGroup': appGroup,
        'key': WidgetStateV1.storageKey,
        'payload': jsonEncode(state.toJson()),
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
