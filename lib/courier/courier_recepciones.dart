import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../design_system/brand_foundations.dart';
import '../design_system/brand_states.dart';
import '../design_system/core_components.dart';
import '../design_system/home_components.dart';
import '../domain/package_stage.dart';
import '../navigation/app_routes.dart';
import '../services/courier_service.dart';
import '../services/model/recepcion.dart';
import '../theme/brand_tokens.dart';

class RecepcionesPage extends StatefulWidget {
  const RecepcionesPage({
    super.key,
    required this.recepciones,
    this.titulo = '',
    this.initialStage,
    this.retained = false,
  });

  final List<Recepcion> recepciones;
  final String titulo;
  final PackageStage? initialStage;

  /// Held packages: opening one goes straight to its post-alert, the way the
  /// operation expects the invoice to arrive, instead of to its history.
  final bool retained;

  @override
  State<RecepcionesPage> createState() => _RecepcionesPageState();
}

class _RecepcionesPageState extends State<RecepcionesPage> {
  late List<Recepcion> _receptions;
  late PackageStage? _stage;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _receptions = [...widget.recepciones];
    _stage = widget.initialStage;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final visible = _receptions.where((reception) {
      if (_stage == null) return true;
      return _stageFor(reception) == _stage;
    }).toList(growable: false);

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: ScreenHeader(
        title: widget.titulo.isEmpty ? 'recepciones'.tr() : widget.titulo,
        onBack: context.popOrHome,
        trailing: IconButton(
          onPressed: _refreshing ? null : _refresh,
          icon: Icon(Icons.refresh, color: tokens.onPrimary),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_stage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BrandSpace.lg,
                BrandSpace.sm,
                BrandSpace.lg,
                0,
              ),
              child: BrandFilterChip(
                label: _label(_stage!).tr(),
                onClear: () => setState(() => _stage = null),
              ),
            ),
          Expanded(
            child: _refreshing
                ? const BrandSkeleton()
                : visible.isEmpty
                    ? const BrandEmptyState(messageKey: 'no_paquetes')
                    : _stage == null
                        ? _groupedList(visible)
                        : _flatList(visible),
          ),
        ],
      ),
    );
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    final receptions = await GetIt.I<CourierService>().getRecepciones(true);
    if (!mounted) return;
    setState(() {
      _receptions = receptions;
      _refreshing = false;
    });
  }

  String _label(PackageStage stage) => switch (stage) {
        PackageStage.origen => 'recibido',
        PackageStage.ruta => 'en_ruta',
        PackageStage.destino => 'en_destino',
        PackageStage.disponible => 'disponibles',
        PackageStage.entregado => 'entregado',
      };

  Widget _groupedList(List<Recepcion> receptions) {
    final byStage = <PackageStage, List<Recepcion>>{
      for (final stage in _stageOrder) stage: <Recepcion>[],
    };
    for (final reception in receptions) {
      byStage[_stageFor(reception)]!.add(reception);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        BrandSpace.lg,
        BrandSpace.xxs,
        BrandSpace.lg,
        BrandTabBar.height,
      ),
      children: [
        for (final stage in _stageOrder)
          if (byStage[stage]!.isNotEmpty) ...[
            BrandSectionLabel(
              '${_label(stage).tr()} (${byStage[stage]!.length})',
            ),
            for (final reception in byStage[stage]!)
              Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: _packageCard(reception),
              ),
          ],
      ],
    );
  }

  Widget _flatList(List<Recepcion> receptions) => ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          BrandSpace.lg,
          BrandSpace.md,
          BrandSpace.lg,
          BrandTabBar.height,
        ),
        itemCount: receptions.length,
        separatorBuilder: (context, index) => const SizedBox(height: 11),
        itemBuilder: (context, index) => _packageCard(receptions[index]),
      );

  Widget _packageCard(Recepcion reception) => PackageCard(
        package: reception,
        showChevron: true,
        showAmount: reception.disponible,
        onTap: () => context.push(
          widget.retained
              ? AppRoutes.invoice(reception.recepcionID)
              : AppRoutes.package(reception.recepcionID),
          extra: reception,
        ),
      );

  PackageStage _stageFor(Recepcion reception) => PackageStatusMapper.map(
        status: reception.estatus,
        isAvailable: reception.disponible,
        progress: reception.progreso,
      ).stage;

  static const _stageOrder = <PackageStage>[
    PackageStage.disponible,
    PackageStage.origen,
    PackageStage.ruta,
    PackageStage.destino,
    PackageStage.entregado,
  ];
}
