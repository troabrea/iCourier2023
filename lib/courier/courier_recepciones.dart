import 'package:easy_localization/easy_localization.dart';
import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../design_system/brand_foundations.dart';
import '../design_system/brand_states.dart';
import '../design_system/core_components.dart';
import '../design_system/home_components.dart';
import '../domain/package_stage.dart';
import '../navigation/app_routes.dart';
import '../services/app_events.dart';
import '../services/courier_service.dart';
import '../services/model/recepcion.dart';
import '../theme/brand_tokens.dart';

class RecepcionesPage extends StatefulWidget {
  const RecepcionesPage({
    super.key,
    required this.recepciones,
    this.titulo = '',
    this.initialStage,
  });

  final List<Recepcion> recepciones;
  final String titulo;
  final PackageStage? initialStage;

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
      return PackageStatusMapper.map(
            status: reception.estatus,
            isAvailable: reception.disponible,
            progress: reception.progreso,
          ).stage ==
          _stage;
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
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          BrandSpace.lg,
                          BrandSpace.md,
                          BrandSpace.lg,
                          BrandTabBar.height,
                        ),
                        itemCount: visible.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 11),
                        itemBuilder: (context, index) => PackageCard(
                          package: visible[index],
                          onTap: () => context.push(
                            AppRoutes.package(visible[index].recepcionID),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    GetIt.I<Event<CourierRefreshRequested>>()
        .broadcast(CourierRefreshRequested());
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
}
