import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design_system/brand_foundations.dart';
import '../design_system/brand_states.dart';
import '../design_system/core_components.dart';
import '../domain/package_stage.dart';
import '../navigation/app_routes.dart';
import '../services/model/recepcion.dart';
import '../theme/brand_tokens.dart';

/// Canonical destination of every deep link: widget, push and Live Activity
/// all resolve to this screen.
class HistoricoPaquetePage extends StatelessWidget {
  const HistoricoPaquetePage({super.key, required this.recepcion});

  final Recepcion recepcion;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final status = PackageStatusMapper.map(
      status: recepcion.estatus,
      isAvailable: recepcion.disponible,
      progress: recepcion.progreso,
    );
    final events = recepcion.paquetes
        .expand((package) => package.historia)
        .toList(growable: false);
    final needsInvoice = recepcion.retenido && recepcion.fotoFacturaUrl.isEmpty;

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: ScreenHeader(
        title: 'historia_del_paquete'.tr(),
        titleSize: 18,
        onBack: context.popOrHome,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            BrandSpace.lg,
            BrandSpace.md,
            BrandSpace.lg,
            BrandTabBar.height,
          ),
          children: [
            _SummaryCard(package: recepcion, stage: status.stage),
            const SizedBox(height: BrandSpace.lg),
            MacroStepper(stage: status.stage),
            const SizedBox(height: 22),
            if (needsInvoice) ...[
              BrandNotice(
                title: 'retenido_falta_factura'.tr(),
                message: 'adjunta_valor_factura'.tr(),
                glyph: BrandIcons.missingInvoice,
                actionLabel: 'adjuntar_factura'.tr(),
                onAction: () => context.push(
                  AppRoutes.invoice(recepcion.recepcionID),
                ),
              ),
              const SizedBox(height: BrandSpace.md),
            ] else ...[
              BrandOutlineButton(
                label: recepcion.fotoFacturaUrl.isEmpty
                    ? 'crear_post_alerta'.tr()
                    : 'facturas_pendientes'.tr(),
                onPressed: () => context.push(
                  AppRoutes.invoice(recepcion.recepcionID),
                ),
              ),
              const SizedBox(height: BrandSpace.lg),
            ],
            Text('linea_de_tiempo'.tr(), style: tokens.body(13, weight: FontWeight.w700)),
            const SizedBox(height: 10),
            if (events.isEmpty)
              const BrandEmptyState(messageKey: 'no_resultados')
            else
              EventTimeline(
                events: events,
                stage: status.stage,
                retained: recepcion.retenido,
              ),
          ],
        ),
      ),
    );
  }
}

/// Identity of the package: code, state, contents, supplier and amount.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.package, required this.stage});

  final Recepcion package;
  final PackageStage stage;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final meta = [
      if (package.suplidor.isNotEmpty) package.suplidor,
      if (package.totalPeso.isNotEmpty) '${package.totalPeso} ${'lbs'.tr()}',
      if (package.fecha.isNotEmpty) package.fecha,
    ].join(' · ');

    return BrandCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  package.numeroRastreo.isEmpty
                      ? package.recepcionID
                      : package.numeroRastreo,
                  style: tokens.body(11, color: tokens.textMuted),
                ),
              ),
              const SizedBox(width: BrandSpace.xs),
              StatusBadge(
                stage: stage,
                retained: package.retenido,
                available: package.disponible,
              ),
            ],
          ),
          const SizedBox(height: BrandSpace.xxs),
          Text(
            package.contenido.isEmpty ? package.suplidor : package.contenido,
            style: tokens.body(16, weight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  meta,
                  style: tokens.body(12, color: tokens.textMuted),
                ),
              ),
              const SizedBox(width: BrandSpace.xs),
              Text(
                '\$${package.totalNeto}',
                style: tokens.body(14, weight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
