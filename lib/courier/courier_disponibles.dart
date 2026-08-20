import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../design_system/brand_foundations.dart';
import '../design_system/brand_states.dart';
import '../design_system/core_components.dart';
import '../design_system/motion_components.dart';
import '../design_system/overlay_components.dart';
import '../navigation/app_routes.dart';
import '../services/courier_service.dart';
import '../services/model/empresa.dart';
import '../services/model/recepcion.dart';
import '../theme/brand_config.dart';
import '../theme/brand_tokens.dart';

class DisponiblesPage extends StatefulWidget {
  const DisponiblesPage({
    super.key,
    required this.disponibles,
    required this.empresa,
  });

  final List<Recepcion> disponibles;
  final Empresa empresa;

  @override
  State<DisponiblesPage> createState() => _DisponiblesPageState();
}

class _DisponiblesPageState extends State<DisponiblesPage> {
  late List<Recepcion> _packages;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _packages = [...widget.disponibles];
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final config = GetIt.I<BrandConfig>();
    final capabilities = config.capabilities.resolve(widget.empresa);
    final total = _packages.fold<double>(
      0,
      (sum, package) => sum + package.montoTotal(),
    );

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: ScreenHeader(
        title: 'disponibles'.tr(),
        onBack: context.popOrHome,
        trailing: IconButton(
          onPressed: _busy ? null : _refresh,
          icon: Icon(Icons.refresh, color: tokens.onPrimary),
        ),
      ),
      body: Column(
        children: [
          BrandManifestReveal(
            duration: const Duration(milliseconds: 280),
            child: SelectionSummaryBar(
              count: _packages.length,
              total: total,
              currency: r'$',
              capabilities: capabilities,
              onPickup: widget.empresa.hasNotifyModule ? _notifyPickup : null,
              onPay: _payOnline,
              onDelivery: _requestDelivery,
            ),
          ),
          Expanded(
            child: _busy
                ? const BrandSkeleton()
                : _packages.isEmpty
                    ? const BrandEmptyState(
                        messageKey: 'no_paquetes',
                        glyph: BrandIcons.available,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          BrandSpace.lg,
                          BrandSpace.md,
                          BrandSpace.lg,
                          BrandTabBar.height,
                        ),
                        itemCount: _packages.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final package = _packages[index];
                          return BrandManifestReveal(
                            key: ValueKey(
                              'available-${package.recepcionID}',
                            ),
                            delay: brandManifestDelay(
                              index,
                              startMilliseconds: 40,
                            ),
                            duration: const Duration(milliseconds: 300),
                            child: PackageCard(
                              package: package,
                              onTap: () => context.push(
                                AppRoutes.package(package.recepcionID),
                                extra: package,
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _refresh() async {
    setState(() => _busy = true);
    final packages = await GetIt.I<CourierService>().getRecepciones(true);
    if (!mounted) return;
    setState(() {
      _packages = packages.where((package) => package.disponible).toList();
      _busy = false;
    });
  }

  Future<void> _payOnline() async {
    final total = _packages.fold<double>(
      0,
      (sum, package) => sum + package.montoTotal(),
    );
    await showBrandSheet<void>(
      context,
      child: PaymentSheet(
        amount: '\$${total.toStringAsFixed(2)}',
        brandName: GetIt.I<BrandConfig>().name,
        onConfirm: () => GetIt.I<CourierService>().launchOnlinePayment(context),
      ),
    );
  }

  Future<void> _requestDelivery() async {
    await showBrandSheet<void>(
      context,
      child: DeliverySheet(
        count: _packages.length,
        onConfirm: _submitDelivery,
      ),
    );
  }

  Future<void> _submitDelivery() async {
    setState(() => _busy = true);
    final result = await GetIt.I<CourierService>().solicitaDomicilio(
      _packages.map((package) => package.recepcionID).toList(growable: false),
    );
    if (!mounted) return;
    _showResult(result, successKey: 'solicitar_domicilio');
    await _refresh();
  }

  Future<void> _notifyPickup() async {
    await showBrandSheet<void>(
      context,
      child: PickupSheet(
        modes: GetIt.I<BrandConfig>().capabilities.pickupModes,
        count: _packages.length,
        onConfirm: _submitPickup,
      ),
    );
  }

  Future<void> _submitPickup(BrandPickupMode? mode) async {
    setState(() => _busy = true);
    final result = await GetIt.I<CourierService>().notificaRetiro(
      puntoRetiro: mode?.value ?? '',
    );
    if (!mounted) return;
    _showResult(result, successKey: 'retiro_notificado');
    await _refresh();
  }

  void _showResult(String result, {required String successKey}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.isEmpty ? successKey.tr() : result)),
    );
  }
}
