import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../design_system/brand_states.dart';
import '../design_system/core_components.dart';
import '../navigation/app_routes.dart';
import '../services/courier_service.dart';
import '../services/model/empresa.dart';
import '../services/model/recepcion.dart';
import '../theme/brand_config.dart';

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
    final config = GetIt.I<BrandConfig>();
    final capabilities = config.capabilities.resolve(widget.empresa);
    return Scaffold(
      appBar: ScreenHeader(title: 'facturas_pendientes'.tr()),
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
            return const BrandEmptyState(messageKey: 'no_resultados');
          }
          final total = invoices.fold<double>(
            0,
            (sum, invoice) => sum + invoice.montoTotal(),
          );
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    title: Text('total'.tr()),
                    trailing: Text(
                      '${config.currency} ${total.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                if (capabilities.payments)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: FilledButton.icon(
                      onPressed: () => GetIt.I<CourierService>()
                          .launchOnlinePayment(context),
                      icon: const Icon(Icons.payment_outlined),
                      label: Text('realizar_pago'.tr()),
                    ),
                  ),
                for (final invoice in invoices) ...[
                  PackageCard(
                    package: invoice,
                    onTap: () => context.push(
                      AppRoutes.invoice(invoice.recepcionID),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _reload() {
    setState(() {
      _invoices = GetIt.I<CourierService>().getFacturados();
    });
  }
}
