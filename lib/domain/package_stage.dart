import 'dart:developer' as developer;

/// Macroestado compartido por la aplicación y los widgets nativos.
enum PackageStage { origen, ruta, destino, disponible, entregado }

/// Visible stage names; enum values stay stable for saved links and widgets.
extension PackageStageLabel on PackageStage {
  String get labelKey => switch (this) {
        PackageStage.origen => 'origen',
        PackageStage.ruta => 'en_transito',
        PackageStage.destino => 'en_distribucion',
        PackageStage.disponible => 'disponible',
        PackageStage.entregado => 'entregado',
      };
}

/// Resultado normalizado de un estado operativo del backend.
class PackageStatus {
  const PackageStatus({
    required this.stage,
    required this.sourceStatus,
    required this.usedProgressFallback,
  });

  final PackageStage stage;
  final String sourceStatus;
  final bool usedProgressFallback;

  int get step => stage.index + 1;
}

typedef UnknownPackageStatusReporter = void Function(
  String status,
  int progress,
);

/// Única fuente de verdad para convertir eventos operativos en macroestados.
abstract final class PackageStatusMapper {
  /// Matched whole, never as a substring: the operation also reports handovers
  /// such as "Entregado Línea Aérea", which happen at origin and would be read
  /// as the end of the journey by a bare `contains('ENTREGADO')`.
  static const _deliveredTerms = <String>{
    'ENTREGADO AL CLIENTE',
    'ENTREGADO',
    'DELIVERED',
    'BILLED COUNTER',
    // Same handover as 'BILLED COUNTER', which the operation reports in
    // Spanish. Without it the history list shows collected packages sitting at
    // step one, because that endpoint sends no progress to fall back on.
    'FACTURADO COUNTER',
  };

  static const _routeTerms = <String>{
    'EMBARCADO',
    'SHIPMENT SENT',
    'IN TRANSIT',
    'EN RUTA',
    'EN TRANSITO',
    'TRANSITO',
    'ADUANA',
    'CUSTOM',
    'CUSTOMS',
  };

  static const _destinationTerms = <String>{
    'TRANSFERIDO',
    'EMPACADO',
    'TRANSITO A SUCURSAL',
    'TRANSITO HACIA SUCURSAL',
    'IN TRANSIT TO BRANCH',
    'RECIBIDO EN SUCURSAL',
    'RECIBIDO SUCURSAL',
    'RECEIVED AT BRANCH',
    'DISTRIBUCION',
    'RECIBIDO AILA',
    'ALMACEN',
    'WAREHOUSE',
    'DISTRIBUTION CENTER',
    'PACKED',
    'OUTGOING TRANSFER',
    'DESTINO',
  };

  static const _originTerms = <String>{
    'RECIBIDO PARA PROCESAR',
    'LISTO PARA EMBARCACION',
    'RECIBIDO EN ORIGEN',
    'RECIBIDO MIAMI',
    'ORIGIN',
    'RECEIVED',
    'ENTREGADO LINEA AEREA',
  };

  static PackageStatus map({
    required String status,
    required bool isAvailable,
    required int progress,
    UnknownPackageStatusReporter? onUnknown,
  }) {
    final normalized = _normalize(status);

    if (_deliveredTerms.contains(normalized)) {
      return _known(PackageStage.entregado, status);
    }
    if (isAvailable) {
      return _known(PackageStage.disponible, status);
    }
    // Pickup and delivery use the API flag. A label or progress=4 alone must
    // not advertise availability in a different screen or native widget.
    if (isAvailabilityStatus(status)) {
      return _known(PackageStage.destino, status);
    }
    if (_matchesAny(normalized, _destinationTerms)) {
      return _known(PackageStage.destino, status);
    }
    if (_matchesAny(normalized, _routeTerms)) {
      return _known(PackageStage.ruta, status);
    }
    if (_matchesAny(normalized, _originTerms)) {
      return _known(PackageStage.origen, status);
    }

    final reporter = onUnknown ?? _reportUnknown;
    reporter(status, progress);
    return PackageStatus(
      stage: _fromProgress(progress),
      sourceStatus: status,
      usedProgressFallback: true,
    );
  }

  static PackageStatus _known(PackageStage stage, String status) {
    return PackageStatus(
      stage: stage,
      sourceStatus: status,
      usedProgressFallback: false,
    );
  }

  static bool _matchesAny(String status, Set<String> terms) {
    return terms.any((term) => ' $status '.contains(' $term '));
  }

  static bool isAvailabilityStatus(String status) =>
      _matchesAny(_normalize(status), const {'DISPONIBLE', 'AVAILABLE'});

  static PackageStage _fromProgress(int progress) {
    return switch (progress) {
      <= 1 => PackageStage.origen,
      2 => PackageStage.ruta,
      3 => PackageStage.destino,
      4 => PackageStage.destino,
      _ => PackageStage.entregado,
    };
  }

  static String _normalize(String value) {
    return value
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[ÁÀÄÂ]'), 'A')
        .replaceAll(RegExp(r'[ÉÈËÊ]'), 'E')
        .replaceAll(RegExp(r'[ÍÌÏÎ]'), 'I')
        .replaceAll(RegExp(r'[ÓÒÖÔ]'), 'O')
        .replaceAll(RegExp(r'[ÚÙÜÛ]'), 'U')
        .replaceAll('Ñ', 'N')
        .replaceAll(RegExp(r'[^A-Z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static void _reportUnknown(String status, int progress) {
    developer.log(
      'Estado de paquete desconocido: "$status". Fallback a progreso=$progress.',
      name: 'PackageStatusMapper',
    );
  }
}
