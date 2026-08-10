import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../design_system/brand_states.dart';
import '../design_system/core_components.dart';
import '../services/courier_service.dart';
import '../services/model/estado_model.dart';
import '../theme/brand_config.dart';

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
    return Scaffold(
      appBar: ScreenHeader(title: 'estado_de_cuenta'.tr()),
      body: FutureBuilder<List<EstadoResponse>>(
        future: _statement,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return BrandErrorState(onRetry: _reload);
          }
          if (!snapshot.hasData) {
            return const BrandSkeleton();
          }
          if (snapshot.requireData.isEmpty) {
            return const BrandEmptyState(messageKey: 'estado_de_cuenta_vacio');
          }
          final currency = GetIt.I<BrandConfig>().currency;
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.requireData.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = snapshot.requireData[index];
                return Card(
                  child: ListTile(
                    title: Text(item.documento),
                    subtitle: Text(item.soloFecha()),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('$currency ${item.balance.toStringAsFixed(2)}'),
                        Text(
                          item.diasVencidos > 0
                              ? '${'vencido'.tr()} · ${item.diasVencidos} ${'dias'.tr()}'
                              : 'no_vencido'.tr(),
                        ),
                      ],
                    ),
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
