import 'package:easy_localization/easy_localization.dart';
import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../design_system/brand_states.dart';
import '../design_system/core_components.dart';
import '../navigation/app_routes.dart';
import '../services/app_events.dart';
import '../services/courier_service.dart';
import '../services/model/empresa.dart';
import '../services/model/login_model.dart';
import '../theme/brand_config.dart';

class AdicionalInfoPage extends StatefulWidget {
  const AdicionalInfoPage({super.key});

  @override
  State<AdicionalInfoPage> createState() => _AdicionalInfoPageState();
}

class _AdicionalInfoPageState extends State<AdicionalInfoPage> {
  late Future<({UserProfile profile, Empresa company, String version})> _data;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ScreenHeader(title: 'informacion_adicional'.tr()),
      body: FutureBuilder<
          ({UserProfile profile, Empresa company, String version})>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return BrandErrorState(
              onRetry: () => setState(() => _data = _load()),
            );
          }
          if (!snapshot.hasData) {
            return const BrandSkeleton(rows: 7);
          }
          final data = snapshot.requireData;
          final config = GetIt.I<BrandConfig>();
          final capabilities = config.capabilities.resolve(data.company);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      data.profile.nombre.isEmpty
                          ? config.name.characters.first
                          : data.profile.nombre.characters.first,
                    ),
                  ),
                  title: Text(data.profile.nombre),
                  subtitle: Text(
                    [data.profile.cuenta, data.profile.nombreSucursal]
                        .where((value) => value.isNotEmpty)
                        .join(' · '),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.idCard),
                ),
              ),
              const SizedBox(height: 12),
              _RouteTile(
                icon: Icons.switch_account_outlined,
                label: 'sus_cuentas'.tr(),
                route: AppRoutes.accounts,
              ),
              _RouteTile(
                icon: Icons.message_outlined,
                label: 'sus_mensajes'.tr(),
                route: AppRoutes.messages,
              ),
              _RouteTile(
                icon: Icons.history,
                label: 'consulta_historica'.tr(),
                route: AppRoutes.history,
              ),
              _RouteTile(
                icon: Icons.receipt_long_outlined,
                label: 'facturas_pendientes'.tr(),
                route: AppRoutes.invoices,
              ),
              _RouteTile(
                icon: Icons.account_balance_wallet_outlined,
                label: 'estado_de_cuenta'.tr(),
                route: AppRoutes.accountStatement,
                visible: capabilities.payments,
              ),
              _RouteTile(
                icon: Icons.notifications_active_outlined,
                label: 'ver_prealertas'.tr(),
                route: AppRoutes.completedPrealerts,
                visible: capabilities.prealerts,
              ),
              _RouteTile(
                icon: Icons.miscellaneous_services_outlined,
                label: 'servicios'.tr(),
                route: AppRoutes.services,
              ),
              _RouteTile(
                icon: Icons.feed_outlined,
                label: 'noticias'.tr(),
                route: AppRoutes.news,
              ),
              _RouteTile(
                icon: Icons.help_outline,
                label: 'preguntas'.tr(),
                route: AppRoutes.faq,
                visible: data.company.hasPreguntas,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _confirmLogout(context),
                icon: const Icon(Icons.logout),
                label: Text('cerrar_session'.tr()),
              ),
              const SizedBox(height: 20),
              Text(
                'version_info'.tr(args: [data.version]),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          );
        },
      ),
    );
  }

  Future<({UserProfile profile, Empresa company, String version})>
      _load() async {
    final service = GetIt.I<CourierService>();
    final results = await Future.wait([
      service.getUserProfile(),
      service.getEmpresa(),
      PackageInfo.fromPlatform(),
    ]);
    return (
      profile: results[0] as UserProfile,
      company: results[1] as Empresa,
      version: (results[2] as PackageInfo).version,
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('confirme'.tr()),
            content: Text('confirme_cerrar_session'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('cancelar'.tr()),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('cerrar_session'.tr()),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed) {
      GetIt.I<Event<LogoutRequested>>().broadcast(LogoutRequested());
    }
  }
}

class _RouteTile extends StatelessWidget {
  const _RouteTile({
    required this.icon,
    required this.label,
    required this.route,
    this.visible = true,
  });

  final IconData icon;
  final String label;
  final String route;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(route),
      ),
    );
  }
}
