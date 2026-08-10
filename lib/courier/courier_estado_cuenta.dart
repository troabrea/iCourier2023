import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../design_system/brand_foundations.dart';
import '../design_system/brand_states.dart';
import '../design_system/core_components.dart';
import '../services/courier_service.dart';
import '../services/model/estado_model.dart';
import '../theme/brand_config.dart';
import '../theme/brand_tokens.dart';

class EstadoDeCuenta extends StatefulWidget {
  const EstadoDeCuenta({super.key});

  @override
  State<EstadoDeCuenta> createState() => _EstadoDeCuentaState();
}

class _EstadoDeCuentaState extends State<EstadoDeCuenta> {
  late Future<List<EstadoResponse>> _statement;

  @override
  void initState() {
    super.initState();
    _statement = GetIt.I<CourierService>().getEstadoCuenta();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: ScreenHeader(
        title: 'estado_de_cuenta'.tr(),
        titleSize: 18,
        onBack: context.canPop() ? context.pop : null,
      ),
      body: FutureBuilder<List<EstadoResponse>>(
        future: _statement,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return BrandErrorState(onRetry: _reload);
          }
          if (!snapshot.hasData) {
            return const BrandSkeleton();
          }
          final items = snapshot.requireData;
          if (items.isEmpty) {
            return const BrandEmptyState(
              messageKey: 'estado_de_cuenta_vacio',
              glyph: BrandIcons.history,
            );
          }
          final currency = GetIt.I<BrandConfig>().currency;
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                BrandSpace.lg,
                BrandSpace.md,
                BrandSpace.lg,
                BrandTabBar.height,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final overdue = item.diasVencidos > 0;
                return BrandCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.documento,
                              style: tokens.body(14, weight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.soloFecha(),
                              style: tokens.body(11, color: tokens.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: BrandSpace.xs),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$currency${item.balance.toStringAsFixed(2)}',
                            style: tokens.body(14, weight: FontWeight.w700),
                          ),
                          const SizedBox(height: 3),
                          BrandPill(
                            label: overdue
                                ? '${'vencido'.tr()} · ${item.diasVencidos} ${'dias'.tr()}'
                                : 'no_vencido'.tr(),
                            background: tokens.accentWash(
                              overdue ? tokens.danger : tokens.success,
                              0.14,
                            ),
                            foreground:
                                overdue ? tokens.danger : tokens.success,
                            fontSize: 10,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _reload() {
    setState(() {
      _statement = GetIt.I<CourierService>().getEstadoCuenta();
    });
  }
}
