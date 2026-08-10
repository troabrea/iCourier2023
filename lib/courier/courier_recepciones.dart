import 'package:easy_localization/easy_localization.dart';
import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../design_system/brand_states.dart';
import '../design_system/core_components.dart';
import '../domain/package_stage.dart';
import '../navigation/app_routes.dart';
import '../services/app_events.dart';
import '../services/courier_service.dart';
import '../services/model/recepcion.dart';

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
      appBar: ScreenHeader(
        title: widget.titulo.isEmpty ? 'recepciones'.tr() : widget.titulo,
        trailing: IconButton(
          onPressed: _refreshing ? null : _refresh,
          icon: const Icon(Icons.refresh),
        ),
      ),
      body: _refreshing
          ? const BrandSkeleton()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: Text('todo_leido'.tr()),
                        selected: _stage == null,
                        onSelected: (_) => setState(() => _stage = null),
                      ),
                      for (final stage in PackageStage.values) ...[
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text(_label(stage).tr()),
                          selected: _stage == stage,
                          onSelected: (_) => setState(() => _stage = stage),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (visible.isEmpty)
                  const BrandEmptyState(messageKey: 'no_paquetes')
                else
                  for (final reception in visible) ...[
                    PackageCard(
                      package: reception,
                      onTap: () => context.push(
                        AppRoutes.package(reception.recepcionID),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
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
