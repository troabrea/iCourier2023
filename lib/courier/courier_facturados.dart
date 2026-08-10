import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../design_system/brand_foundations.dart';
import '../design_system/brand_states.dart';
import '../design_system/core_components.dart';
import '../design_system/overlay_components.dart';
import '../navigation/app_routes.dart';
import '../services/courier_service.dart';
import '../services/model/empresa.dart';
import '../services/model/recepcion.dart';
import '../theme/brand_config.dart';
import '../theme/brand_tokens.dart';

class FacturadosPage extends StatefulWidget {
  const FacturadosPage({super.key, required this.empresa});

  final Empresa empresa;

  @override
  State<FacturadosPage> createState() => _FacturadosPageState();
}

class _FacturadosPageState extends State<FacturadosPage> {
  late Future<List<Recepcion>> _invoices;

  @override
  void initState() {
    super.initState();
    _invoices = GetIt.I<CourierService>().getFacturados();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final config = GetIt.I<BrandConfig>();
    final capabilities = config.capabilities.resolve(widget.empresa);

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: ScreenHeader(
        title: 'facturas_pendientes'.tr(),
        titleSize: 18,
        onBack: context.canPop() ? context.pop : null,
      ),
      body: FutureBuilder<List<Recepcion>>(
        future: _invoices,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return BrandErrorState(onRetry: _reload);
          }
          if (!snapshot.hasData) {
            return const BrandSkeleton();
          }
          final invoices = snapshot.requireData;
          if (invoices.isEmpty) {
            return const BrandEmptyState(
              messageKey: 'no_resultados',
              glyph: BrandIcons.missingInvoice,
            );
          }
          final total = invoices.fold<double>(
            0,
            (sum, invoice) => sum + invoice.montoTotal(),
          );
          return Column(
            children: [
              ColoredBox(
                color: tokens.surfaceAlt,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BrandSpace.lg,
                    vertical: BrandSpace.md,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'total'.tr(),
                              style: tokens.body(
                                11,
                                color: tokens.textMuted,
                              ),
                            ),
                            Text(
                              '${config.currency}${total.toStringAsFixed(2)}',
                              style: tokens.head(20),
                            ),
                          ],
                        ),
                      ),
                      if (capabilities.payments)
                        BrandPrimaryButton(
                          label: 'realizar_pago'.tr(),
                          expand: false,
                          fontSize: 13,
                          verticalPadding: 11,
                          onPressed: () => _pay(total),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      BrandSpace.lg,
                      BrandSpace.md,
                      BrandSpace.lg,
                      BrandTabBar.height,
                    ),
                    itemCount: invoices.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 11),
                    itemBuilder: (context, index) => PackageCard(
                      package: invoices[index],
                      onTap: () => context.push(
                        AppRoutes.invoice(invoices[index].recepcionID),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pay(double total) async {
    await showBrandSheet<void>(
      context,
      child: PaymentSheet(
        amount:
            '${GetIt.I<BrandConfig>().currency}${total.toStringAsFixed(2)}',
        brandName: GetIt.I<BrandConfig>().name,
        onConfirm: () => GetIt.I<CourierService>().launchOnlinePayment(context),
      ),
    );
  }

  void _reload() {
    setState(() {
      _invoices = GetIt.I<CourierService>().getFacturados();
    });
  }
}
