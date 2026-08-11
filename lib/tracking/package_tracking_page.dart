import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../design_system/brand_foundations.dart';
import '../design_system/brand_states.dart';
import '../design_system/core_components.dart';
import '../domain/package_stage.dart';
import '../navigation/app_routes.dart';
import '../services/courier_service.dart';
import '../services/model/recepcion.dart';
import '../theme/brand_tokens.dart';

/// Three states, as the design reference specifies: idle, no result, and a
/// found package with its card, timeline and a link to the full detail.
class PackageTrackingPage extends StatefulWidget {
  const PackageTrackingPage({super.key, this.initialQuery = ''});

  /// Preloaded by the `<scheme>://rastreo?q=` deep link.
  final String initialQuery;

  @override
  State<PackageTrackingPage> createState() => _PackageTrackingPageState();
}

class _PackageTrackingPageState extends State<PackageTrackingPage> {
  late final TextEditingController _controller;
  Future<Recepcion?>? _result;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    if (widget.initialQuery.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _search());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: ScreenHeader(
        title: 'rastreo_paquete'.tr(),
        onBack: context.popOrHome,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            BrandSpace.lg,
            18,
            BrandSpace.lg,
            BrandTabBar.height,
          ),
          children: [
            Text(
              'numero_rastreo'.tr().toUpperCase(),
              style: tokens.eyebrow(10),
            ),
            const SizedBox(height: BrandSpace.xs),
            BrandCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Row(
                children: [
                  BrandGlyph(
                    BrandIcons.track,
                    color: tokens.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                      style: tokens.body(
                        15,
                        weight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                      decoration: InputDecoration(
                        hintText: 'numero_rastreo'.tr(),
                        hintStyle: tokens.body(15, color: tokens.textMuted),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: BrandSpace.sm),
            BrandPrimaryButton(
              label: 'rastrear_paquete'.tr().replaceAll('\n', ' '),
              onPressed: _search,
            ),
            _buildResult(),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final result = _result;
    if (result == null) {
      return const BrandEmptyState(
        messageKey: 'rastreo_ayuda',
        glyph: BrandIcons.track,
      );
    }
    return FutureBuilder<Recepcion?>(
      future: result,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.only(top: BrandSpace.md),
            child: BrandSkeleton(rows: 2),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.only(top: BrandSpace.md),
            child: BrandErrorState(onRetry: _search),
          );
        }
        final reception = snapshot.data;
        return reception == null
            ? const _NotFound()
            : _Found(package: reception);
      },
    );
  }

  void _search() {
    FocusScope.of(context).unfocus();
    final value = _controller.text.trim();
    if (value.isEmpty) {
      return;
    }
    setState(() {
      _result = GetIt.I<CourierService>().getRecepciones(false).then(
            (receptions) => receptions.cast<Recepcion?>().firstWhere(
                  (reception) =>
                      reception?.numeroRastreo.toLowerCase() ==
                          value.toLowerCase() ||
                      reception?.recepcionID.toLowerCase() ==
                          value.toLowerCase(),
                  orElse: () => null,
                ),
          );
    });
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: BrandCard(
        color: tokens.surfaceAlt,
        padding: const EdgeInsets.all(BrandSpace.md),
        child: Column(
          children: [
            Text(
              'sin_resultados_titulo'.tr(),
              style: tokens.body(14, weight: FontWeight.w700),
            ),
            const SizedBox(height: BrandSpace.xxs),
            Text(
              'sin_resultados_cuerpo'.tr(),
              textAlign: TextAlign.center,
              style: tokens.body(12, color: tokens.textMuted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _Found extends StatelessWidget {
  const _Found({required this.package});

  final Recepcion package;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final status = PackageStatusMapper.map(
      status: package.estatus,
      isAvailable: package.disponible,
      progress: package.progreso,
    );
    final events = package.paquetes
        .expand((paquete) => paquete.historia)
        .toList(growable: false);

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BrandCard(
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
                      stage: status.stage,
                      retained: package.retenido,
                      available: package.disponible,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  package.contenido.isEmpty
                      ? package.suplidor
                      : package.contenido,
                  style: tokens.body(16, weight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (package.suplidor.isNotEmpty) package.suplidor,
                    if (package.totalPeso.isNotEmpty)
                      '${package.totalPeso} ${'lbs'.tr()}',
                    if (package.fecha.isNotEmpty) package.fecha,
                  ].join(' · '),
                  style: tokens.body(12, color: tokens.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (events.isNotEmpty) ...[
            Text(
              'linea_de_tiempo'.tr(),
              style: tokens.body(13, weight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            EventTimeline(
              events: events,
              stage: status.stage,
              retained: package.retenido,
              dotSize: 11,
              spacing: 16,
            ),
          ],
          BrandOutlineButton(
            label: 'ver_detalle_completo'.tr(),
            foreground: tokens.primary,
            verticalPadding: 12,
            onPressed: () => context.push(
              AppRoutes.package(package.recepcionID),
            ),
          ),
        ],
      ),
    );
  }
}
