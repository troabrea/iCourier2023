import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icourier/domain/package_stage.dart';
import 'package:icourier/services/model/recepcion.dart';
import 'package:icourier/theme/brand_config.dart';
import 'package:icourier/widget/widget_state_v1.dart';

void main() {
  final config = BrandConfig.fromJson(const {
    'slug': 'bmcargo',
    'name': 'BM Cargo',
    'urlScheme': 'bmcargo',
    'appGroup': 'group.com.barolit.bmcargo',
  });
  final now = DateTime.parse('2026-08-10T09:12:00-04:00');

  test('construye el payload V1 y vence exactamente a las cuatro horas', () {
    final state = WidgetSnapshotBuilder.build(
      config: config,
      brightness: Brightness.light,
      accountCode: 'BM-002332',
      accountName: 'Baroli Technologies',
      packages: [_reception('1', 'Embarcado', progress: 2)],
      generatedAt: now,
    );

    expect(state.toJson()['schema'], 1);
    expect(state.featured?.stage, PackageStage.ruta);
    expect(state.deepLink, 'bmcargo://paquete/1');
    expect(state.staleAfter, now.add(const Duration(hours: 4)));
    expect(state.isStaleAt(now.add(const Duration(hours: 4))), isTrue);
    expect(
      state.isStaleAt(now.add(const Duration(hours: 4, seconds: 1))),
      isTrue,
    );
  });

  test('prioriza disponible, retenido, tránsito y origen', () {
    final state = WidgetSnapshotBuilder.build(
      config: config,
      brightness: Brightness.dark,
      accountCode: 'BM-002332',
      accountName: 'Baroli Technologies',
      packages: [
        _reception('origen', 'Recibido para procesar', progress: 1),
        _reception('ruta', 'Embarcado', progress: 2),
        _reception('retenido', 'Aduana', progress: 3, retained: true),
        _reception('disponible', 'Disponible', progress: 4, available: true),
      ],
      generatedAt: now,
    );

    expect(state.featured?.id, 'disponible');
    expect(state.counts.available, 1);
    expect(state.counts.retained, 1);
    expect(state.counts.inRoute, 2);
    expect(state.counts.inProcess, 1);
  });

  test('desempata por el evento más reciente', () {
    final state = WidgetSnapshotBuilder.build(
      config: config,
      brightness: Brightness.light,
      accountCode: 'BM-002332',
      accountName: 'Baroli Technologies',
      packages: [
        _reception('anterior', 'Embarcado',
            progress: 2, date: '2026-08-09T10:00:00'),
        _reception('reciente', 'Embarcado',
            progress: 2, date: '2026-08-10T10:00:00'),
      ],
      generatedAt: now,
    );

    expect(state.featured?.id, 'reciente');
  });

  test('estado sin sesión no conserva datos de cuenta ni paquetes', () {
    final state = WidgetSnapshotBuilder.signedOut(
      config: config,
      brightness: Brightness.light,
      generatedAt: now,
    );

    expect(state.session.signedIn, isFalse);
    expect(state.session.accountCode, isEmpty);
    expect(state.featured, isNull);
    expect(state.counts.total, 0);
    expect(state.deepLink, 'bmcargo://login');
  });

  test('cambio de cuenta sustituye identidad y destino del snapshot', () {
    final first = WidgetSnapshotBuilder.build(
      config: config,
      brightness: Brightness.light,
      accountCode: 'BM-1',
      accountName: 'Primera',
      packages: const [],
      generatedAt: now,
    );
    final second = WidgetSnapshotBuilder.build(
      config: config,
      brightness: Brightness.dark,
      accountCode: 'BM-2',
      accountName: 'Segunda',
      packages: const [],
      generatedAt: now.add(const Duration(minutes: 1)),
    );

    expect(first.session.accountCode, 'BM-1');
    expect(second.session.accountCode, 'BM-2');
    expect(second.session.accountName, 'Segunda');
    expect(second.deepLink, 'bmcargo://inicio');
    expect(second.brand.primary, isNot(first.brand.primary));
  });
}

Recepcion _reception(
  String id,
  String status, {
  required int progress,
  bool available = false,
  bool retained = false,
  String date = '2026-08-10T09:00:00',
}) {
  return Recepcion(
    recepcionID: id,
    fecha: '2026-08-10',
    producto: 'Aéreo',
    suplidor: 'Amazon',
    cantidadPaquetes: 1,
    contenido: 'Contenido',
    enviadoPor: 'Amazon',
    totalPeso: '1',
    totalVolumen: '0',
    totalNeto: '10.00',
    estatus: status,
    retenido: retained,
    disponible: available,
    paquetes: const [],
    fotoPaqueteSmallUrl: '',
    fotoPaqueteUrl: '',
    fotoFacturaUrl: '',
    fechaHora: date,
    progreso: progress,
    numeroRastreo: id,
  );
}
