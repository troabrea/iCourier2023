import 'dart:async';

import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache/flutter_cache.dart' as cache;

import '../services/app_events.dart';
import '../services/courier_service.dart';
import '../theme/brand_config.dart';
import 'widget_state_store.dart';
import 'widget_state_v1.dart';

/// Keeps the native widget snapshot aligned with the authenticated app state.
///
/// Flutter writes immediately after app refreshes. The native providers may
/// also refresh an older snapshot in the background with the shared session.
final class WidgetSyncCoordinator {
  WidgetSyncCoordinator({
    required BrandConfig config,
    required CourierService courierService,
    required WidgetStateStore store,
    required Brightness initialBrightness,
    DateTime Function()? clock,
  })  : _config = config,
        _courierService = courierService,
        _store = store,
        _brightness = initialBrightness,
        _clock = clock ?? DateTime.now;

  final BrandConfig _config;
  final CourierService _courierService;
  final WidgetStateStore _store;
  final DateTime Function() _clock;
  Brightness _brightness;
  String _accountCode = '';
  String _accountName = '';
  bool _signedIn = false;
  bool _started = false;
  Future<void> _pendingWrite = Future<void>.value();

  void start({
    required Event<LoginChanged> loginChanges,
    required Event<CourierRefreshRequested> refreshRequests,
    required Event<SessionExpired> sessionExpirations,
  }) {
    if (_started || !_config.capabilities.widgets) {
      return;
    }
    _started = true;
    loginChanges.subscribe((change) {
      if (change == null) {
        return;
      }
      _signedIn = change.loggedIn;
      _accountCode = change.account;
      _accountName = change.name;
      _enqueue(change.loggedIn ? refresh : clearForSignedOut);
    });
    refreshRequests.subscribe((_) => _enqueue(refresh));
    sessionExpirations.subscribe((_) => _enqueue(clearForSignedOut));
    _enqueue(_restoreSessionAndRefresh);
  }

  void updateBrightness(Brightness brightness) {
    if (_brightness == brightness) {
      return;
    }
    _brightness = brightness;
    _enqueue(_signedIn ? refresh : clearForSignedOut);
  }

  /// Refreshes the native snapshot whenever the application becomes active.
  void refreshAfterForeground() {
    if (!_started || !_config.capabilities.widgets) {
      return;
    }
    _enqueue(_signedIn ? refresh : clearForSignedOut);
  }

  Future<void> refresh() async {
    if (!_config.capabilities.widgets || !_signedIn) {
      return;
    }
    final accountCode = _accountCode;
    final accountName = _accountName;
    final packages = await _courierService.getRecepciones(false);
    // A switch may finish while the previous account's request is in flight.
    // Never combine that response with the identity that arrived afterwards.
    if (!_signedIn || accountCode != _accountCode) {
      return;
    }
    final persistedAccount = (await cache.load('userAccount', '')).toString();
    if (persistedAccount != accountCode) {
      return;
    }
    final snapshot = WidgetSnapshotBuilder.build(
      config: _config,
      brightness: _brightness,
      accountCode: accountCode,
      accountName: accountName,
      packages: packages,
      generatedAt: _clock(),
    );
    final sessionId = (await cache.load('sessionId', '')).toString();
    await _store.write(
      snapshot,
      appGroup: _config.appGroup,
      logoAsset: _config.assets.logoMark,
      remoteSession: WidgetRemoteSession(
        sessionId: sessionId,
        companyId: _courierService.companyId,
        endpoint: CourierService.receptionsEndpoint,
      ),
    );
  }

  Future<void> clearForSignedOut() async {
    _signedIn = false;
    _accountCode = '';
    _accountName = '';
    await _store.clear(appGroup: _config.appGroup);
    await _store.write(
      WidgetSnapshotBuilder.signedOut(
        config: _config,
        brightness: _brightness,
        generatedAt: _clock(),
      ),
      appGroup: _config.appGroup,
      logoAsset: _config.assets.logoMark,
      remoteSession: WidgetRemoteSession(
        sessionId: '',
        companyId: _courierService.companyId,
        endpoint: CourierService.receptionsEndpoint,
      ),
    );
  }

  Future<void> _restoreSessionAndRefresh() async {
    final sessionId = (await cache.load('sessionId', '')).toString();
    _accountCode = (await cache.load('userAccount', '')).toString();
    _accountName = (await cache.load('userName', '')).toString();
    _signedIn = sessionId.isNotEmpty && _accountCode.isNotEmpty;
    if (_signedIn) {
      await refresh();
    } else {
      await clearForSignedOut();
    }
  }

  void _enqueue(Future<void> Function() operation) {
    _pendingWrite = _pendingWrite.then((_) => operation()).catchError(
      (Object error, StackTrace stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'iCourier widget sync',
          ),
        );
      },
    );
  }
}
