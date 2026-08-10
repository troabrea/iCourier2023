import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design_system/core_components.dart';
import '../domain/package_stage.dart';
import '../navigation/app_routes.dart';
import '../services/model/recepcion.dart';

class HistoricoPaquetePage extends StatelessWidget {
  const HistoricoPaquetePage({super.key, required this.recepcion});

  final Recepcion recepcion;

  @override
  Widget build(BuildContext context) {
    final status = PackageStatusMapper.map(
      status: recepcion.estatus,
      isAvailable: recepcion.disponible,
      progress: recepcion.progreso,
    );
    final events = recepcion.paquetes
        .expand((package) => package.historia)
        .toList(growable: false);
    return Scaffold(
      appBar: ScreenHeader(title: 'historia_del_paquete'.tr()),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            PackageCard(package: recepcion),
            const SizedBox(height: 16),
            MacroStepper(stage: status.stage),
            const SizedBox(height: 20),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text('proveedor'.tr()),
                    trailing: Text(recepcion.suplidor),
                  ),
                  ListTile(
                    title: Text('libras'.tr()),
                    trailing: Text(recepcion.totalPeso),
                  ),
                  ListTile(
                    title: Text('total'.tr()),
                    trailing: Text(recepcion.totalNeto),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push(
                AppRoutes.invoice(recepcion.recepcionID),
              ),
              icon: const Icon(Icons.receipt_long_outlined),
              label: Text(
                recepcion.fotoFacturaUrl.isEmpty
                    ? 'crear_post_alerta'.tr()
                    : 'facturas_pendientes'.tr(),
              ),
            ),
            const SizedBox(height: 20),
            EventTimeline(events: events, stage: status.stage),
          ],
        ),
      ),
    );
  }
}
