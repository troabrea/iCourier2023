import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../design_system/brand_foundations.dart';
import '../design_system/brand_states.dart';
import '../design_system/core_components.dart';
import '../navigation/app_routes.dart';
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
        onBack: context.popOrHome,
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
          final vencido = items
              .where((item) => item.vencido)
              .fold<double>(0, (sum, item) => sum + item.balance);
          final total =
              items.fold<double>(0, (sum, item) => sum + item.balance);
          return Column(
            children: [
              _Totals(
                currency: currency,
                noVencido: total - vencido,
                vencido: vencido,
                total: total,
              ),
              Expanded(
                child: RefreshIndicator(
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
                      final overdue = item.vencido;
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
                                    style: tokens.body(14,
                                        weight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.soloFecha(),
                                    style: tokens.body(11,
                                        color: tokens.textMuted),
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
                                  style:
                                      tokens.body(14, weight: FontWeight.w700),
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
                ),
              ),
            ],
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

class _Totals extends StatelessWidget {
  const _Totals({
    required this.currency,
    required this.noVencido,
    required this.vencido,
    required this.total,
  });

  final String currency;
  final double noVencido;
  final double vencido;
  final double total;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    Widget figure(String labelKey, double amount, {Color? color}) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                labelKey.tr(),
                style: tokens.body(11, color: tokens.textMuted),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '$currency${amount.toStringAsFixed(2)}',
                  style: tokens.head(17, color: color),
                ),
              ),
            ],
          ),
        );
    return ColoredBox(
      color: tokens.surfaceAlt,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BrandSpace.lg,
          vertical: BrandSpace.md,
        ),
        child: Row(
          children: [
            figure('no_vencido', noVencido),
            const SizedBox(width: BrandSpace.sm),
            figure('vencido', vencido,
                color: vencido > 0 ? tokens.danger : null),
            const SizedBox(width: BrandSpace.sm),
            figure('total', total),
          ],
        ),
      ),
    );
  }
}
