import 'package:flutter_test/flutter_test.dart';
import 'package:icourier/domain/package_stage.dart';

void main() {
  group('PackageStatusMapper', () {
    test('normaliza eventos conocidos en español e inglés', () {
      expect(_map('Embarcado').stage, PackageStage.ruta);
      expect(_map('Shipment sent').stage, PackageStage.ruta);
      expect(_map('Distribución').stage, PackageStage.destino);
      expect(_map('Delivered').stage, PackageStage.entregado);
    });

    test('disponible prevalece sobre un estado operativo no entregado', () {
      final result = PackageStatusMapper.map(
        status: 'En almacén',
        isAvailable: true,
        progress: 3,
      );

      expect(result.stage, PackageStage.disponible);
      expect(result.usedProgressFallback, isFalse);
    });

    test('usa progreso y reporta estados desconocidos', () {
      String? reportedStatus;
      int? reportedProgress;

      final result = PackageStatusMapper.map(
        status: 'Nuevo evento de operador',
        isAvailable: false,
        progress: 3,
        onUnknown: (status, progress) {
          reportedStatus = status;
          reportedProgress = progress;
        },
      );

      expect(result.stage, PackageStage.destino);
      expect(result.usedProgressFallback, isTrue);
      expect(reportedStatus, 'Nuevo evento de operador');
      expect(reportedProgress, 3);
    });
  });
}

PackageStatus _map(String status) {
  return PackageStatusMapper.map(
    status: status,
    isAvailable: false,
    progress: 1,
  );
}
