import 'dart:async';

import 'package:flutter/services.dart';

/// Delivers one native pickup request through login and the confirmation UI.
final class AppIntentBridge {
  AppIntentBridge({required this.openPickup, MethodChannel? channel})
      : _channel =
            channel ?? const MethodChannel('icourier_app_intent_channel');

  final void Function(String id) openPickup;
  final MethodChannel _channel;
  final _pending = <String, Completer<bool>>{};
  final _presented = <String>{};
  final _completed = <String>{};

  Future<void> start() async {
    _channel.setMethodCallHandler(_handle);
    await _channel.invokeMethod<void>('ready');
  }

  Future<dynamic> _handle(MethodCall call) async {
    if (call.method != 'notificar_retiro') {
      throw MissingPluginException('Unknown app intent: ${call.method}');
    }
    final arguments = call.arguments;
    final id = arguments is Map ? arguments['id'] : null;
    if (id is! String || id.isEmpty) {
      throw PlatformException(code: 'INVALID_APP_INTENT');
    }
    if (_completed.contains(id)) {
      return true;
    }
    final existing = _pending[id];
    if (existing != null) {
      return existing.future;
    }
    final completion = Completer<bool>();
    _pending[id] = completion;
    try {
      openPickup(id);
    } catch (_) {
      _pending.remove(id);
      rethrow;
    }
    return completion.future;
  }

  /// Prevents a route rebuild from presenting the same request twice.
  bool beginPresentation(String id) =>
      _pending.containsKey(id) && _presented.add(id);

  /// A cancelled confirmation also consumes the request; it must not reopen.
  void complete(String id) {
    final completion = _pending.remove(id);
    if (completion == null) {
      return;
    }
    _completed.add(id);
    completion.complete(true);
  }

  void dispose() {
    _channel.setMethodCallHandler(null);
    for (final completion in _pending.values) {
      completion.complete(false);
    }
    _pending.clear();
  }
}
