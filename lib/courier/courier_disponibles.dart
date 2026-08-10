import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../design_system/brand_states.dart';
import '../design_system/core_components.dart';
import '../services/courier_service.dart';
import '../services/model/empresa.dart';
import '../services/model/recepcion.dart';
import '../theme/brand_config.dart';

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
      appBar: ScreenHeader(
        title: 'disponibles'.tr(),
        trailing: IconButton(
          onPressed: _busy ? null : _refresh,
          icon: const Icon(Icons.refresh),
        ),
      ),
      body: _busy
          ? const BrandSkeleton()
          : _packages.isEmpty
              ? const BrandEmptyState(messageKey: 'no_paquetes')
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 180),
                  children: [
                    Card(
                      child: ListTile(
                        title: Text(
                          '${_packages.length} · ${'cantidad'.tr()}',
                        ),
                        trailing: Text(
                          '${config.currency} ${_packages.fold<double>(0, (sum, package) => sum + package.montoTotal()).toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final package in _packages)
                      SelectableRow(
                        package: package,
                        checked: _selected.contains(package.recepcionID),
                        onToggle: (checked) => setState(() {
                          if (checked) {
                            _selected.add(package.recepcionID);
                          } else {
                            _selected.remove(package.recepcionID);
                          }
                        }),
                      ),
                  ],
                ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (capabilities.delivery && selectedPackages.isNotEmpty)
            SafeArea(
              top: false,
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _requestDelivery,
                    icon: const Icon(Icons.local_shipping_outlined),
                    label: Text('solicitar_domicilio'.tr()),
                  ),
                ),
              ),
            ),
          if (widget.empresa.hasNotifyModule)
            SafeArea(
              top: false,
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _busy ? null : _notifyPickup,
                    icon: const Icon(Icons.meeting_room_outlined),
                    label: Text('notificar_retiro'.tr()),
                  ),
                ),
              ),
            ),
          SelectionSummaryBar(
            count: selectedPackages.length,
            total: selectedTotal,
            currency: config.currency,
            paymentsEnabled: capabilities.payments,
            onPay: () => GetIt.I<CourierService>().launchOnlinePayment(context),
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

  Future<void> _requestDelivery() async {
    setState(() => _busy = true);
    final result = await GetIt.I<CourierService>().solicitaDomicilio(
      _selected.toList(growable: false),
    );
    if (!mounted) return;
    _showResult(result, successKey: 'solicitar_domicilio');
    await _refresh();
  }

  Future<void> _notifyPickup() async {
    final confirmed = await _confirm('seguro_notificar_retiro'.tr());
    if (!confirmed) return;
    setState(() => _busy = true);
    final result = await GetIt.I<CourierService>().notificaRetiro();
    if (!mounted) return;
    _showResult(result, successKey: 'retiro_notificado');
    await _refresh();
  }

  Future<bool> _confirm(String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('confirme'.tr()),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('no'.tr()),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('si'.tr()),
            ),
          ],
        ),
      ) ??
      false;

  void _showResult(String result, {required String successKey}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.isEmpty ? successKey.tr() : result)),
    );
  }
}
