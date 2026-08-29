import 'dart:async';

import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache/flutter_cache.dart' as cache;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/apps/appinfo.dart';
import 'package:icourier/apps/bmcargo/appinfo_bmcargo.dart';
import 'package:icourier/services/app_events.dart';
import 'package:icourier/services/courier_service.dart';
import 'package:icourier/services/model/recepcion.dart';
import 'package:icourier/widget/widget_state_store.dart';
import 'package:icourier/widget/widget_state_v1.dart';
import 'package:icourier/widget/widget_sync_coordinator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/brand_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GetIt.I.reset();
    GetIt.I.registerSingleton<AppInfo>(BmcargoAppInfo());
  });

  tearDown(() => GetIt.I.reset());

  test('never publishes a new identity with packages from an older account',
      () async {
    await cache.write('sessionId', 'session-one');
    await cache.write('userAccount', 'BM-001');
    await cache.write('userName', 'Alicia');
    final service = _DelayedReceptionsService();
    final store = _RecordingWidgetStore();
    final loginChanges = Event<LoginChanged>();
    final coordinator = WidgetSyncCoordinator(
      config: loadTestBrand('bmcargo'),
      courierService: service,
      store: store,
      initialBrightness: Brightness.light,
    );
    coordinator.start(
      loginChanges: loginChanges,
      refreshRequests: Event<CourierRefreshRequested>(),
      sessionExpirations: Event<SessionExpired>(),
    );

    await service.firstCallStarted.future;
    await cache.write('sessionId', 'session-two');
    await cache.write('userAccount', 'BM-002');
    await cache.write('userName', 'Bruno');
    loginChanges.broadcast(LoginChanged(true, 'BM-002', 'Bruno'));
    service.firstCall.complete([_reception('package-one')]);

    await _waitUntil(() => store.states.any(
          (state) => state.session.accountCode == 'BM-002',
        ));

    expect(
      store.states.where(
        (state) =>
            state.session.accountCode == 'BM-002' &&
            state.featured?.id == 'package-one',
      ),
      isEmpty,
    );
    expect(store.states.last.session.accountCode, 'BM-002');
    expect(store.states.last.featured?.id, 'package-two');
  });
}

Future<void> _waitUntil(bool Function() condition) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (condition()) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Timed out waiting for the widget snapshot.');
}

final class _DelayedReceptionsService extends CourierService {
  final firstCallStarted = Completer<void>();
  final firstCall = Completer<List<Recepcion>>();
  var _calls = 0;

  @override
  Future<List<Recepcion>> getRecepciones(bool forceRefresh) async {
    _calls++;
    if (_calls == 1) {
      firstCallStarted.complete();
      return firstCall.future;
    }
    return [_reception('package-two')];
  }
}

final class _RecordingWidgetStore implements WidgetStateStore {
  final states = <WidgetStateV1>[];

  @override
  Future<void> clear({required String appGroup}) async {}

  @override
  Future<void> write(
    WidgetStateV1 state, {
    required String appGroup,
    required String logoAsset,
    required WidgetRemoteSession remoteSession,
  }) async {
    states.add(state);
  }
}

Recepcion _reception(String id) => Recepcion(
      recepcionID: id,
      fecha: '2026.08.28',
      producto: 'Libra',
      suplidor: 'Proveedor',
      cantidadPaquetes: 1,
      contenido: id,
      enviadoPor: '',
      totalPeso: '1',
      totalVolumen: '',
      totalNeto: '10.00',
      estatus: 'Embarcado',
      retenido: false,
      disponible: false,
      paquetes: const [],
      fotoPaqueteSmallUrl: '',
      fotoPaqueteUrl: '',
      fotoFacturaUrl: '',
      fechaHora: '2026-08-28T12:00:00',
      progreso: 2,
      numeroRastreo: id,
    );
