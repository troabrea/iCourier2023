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

class DisponiblesPage extends StatefulWidget {
  const DisponiblesPage({
    super.key,
    required this.disponibles,
    required this.montoTotal,
    required this.empresa,
  });

  final List<Recepcion> disponibles;
  final Empresa empresa;
  final double montoTotal;

  @override
  State<DisponiblesPage> createState() => _DisponiblesPageState();
}

class _DisponiblesPageState extends State<DisponiblesPage> {
  late List<Recepcion> _packages;
  final Set<String> _selected = {};
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
    final selectedPackages = _packages
        .where((package) => _selected.contains(package.recepcionID))
        .toList(growable: false);
    final selectedTotal = selectedPackages.fold<double>(
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
          SelectionSummaryBar(
            count: selectedPackages.length,
            total: selectedTotal,
            currency: r'$',
            capabilities: capabilities,
            onPickup: widget.empresa.hasNotifyModule ? _notifyPickup : null,
            onPay: _payOnline,
            onDelivery: _requestDelivery,
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
                          return SelectableRow(
                            package: package,
                            checked: _selected.contains(package.recepcionID),
                            onOpen: () => context.push(
                              AppRoutes.package(package.recepcionID),
                            ),
                            onToggle: (checked) => setState(() {
                              if (checked) {
                                _selected.add(package.recepcionID);
                              } else {
                                _selected.remove(package.recepcionID);
                              }
                            }),
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
      _selected.removeWhere(
        (id) => !_packages.any((package) => package.recepcionID == id),
      );
      _busy = false;
    });
  }

  Future<void> _payOnline() async {
    final total = _selected.isEmpty
        ? widget.montoTotal
        : _packages
            .where((package) => _selected.contains(package.recepcionID))
            .fold<double>(0, (sum, package) => sum + package.montoTotal());
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
        count: _selected.length,
        onConfirm: _submitDelivery,
      ),
    );
  }

  Future<void> _submitDelivery() async {
    setState(() => _busy = true);
    final result = await GetIt.I<CourierService>().solicitaDomicilio(
      _selected.toList(growable: false),
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
        count: _selected.isEmpty ? _packages.length : _selected.length,
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
