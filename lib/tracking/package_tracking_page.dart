import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../design_system/brand_states.dart';
import '../navigation/app_routes.dart';
import '../services/courier_service.dart';
import '../services/model/recepcion.dart';

class PackageTrackingPage extends StatefulWidget {
  const PackageTrackingPage({super.key});

  @override
  State<PackageTrackingPage> createState() => _PackageTrackingPageState();
}

class _PackageTrackingPageState extends State<PackageTrackingPage> {
  final _controller = TextEditingController();
  Future<Recepcion?>? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('rastreo_paquete'.tr())),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: 'numero_rastreo'.tr(),
                  suffixIcon: IconButton(
                    tooltip: 'buscar'.tr(),
                    onPressed: _search,
                    icon: const Icon(Icons.search),
                  ),
                ),
                onSubmitted: (_) => _search(),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildResult()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResult() {
    final result = _result;
    if (result == null) {
      return const SizedBox.shrink();
    }
    return FutureBuilder<Recepcion?>(
      future: result,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const BrandSkeleton(rows: 2);
        }
        if (snapshot.hasError) {
          return BrandErrorState(onRetry: _search);
        }
        final reception = snapshot.data;
        if (reception == null) {
          return const BrandEmptyState(messageKey: 'no_resultados');
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.push(AppRoutes.package(reception.recepcionID));
          }
        });
        return const SizedBox.shrink();
      },
    );
  }

  void _search() {
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
