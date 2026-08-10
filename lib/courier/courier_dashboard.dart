import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../design_system/brand_states.dart';
import '../design_system/content_components.dart';
import '../design_system/core_components.dart';
import '../navigation/app_routes.dart';
import '../services/courier_service.dart';
import '../services/model/login_model.dart';
import '../theme/brand_config.dart';
import 'bloc/dashboard_bloc.dart';

class CourierDashboard extends StatefulWidget {
  const CourierDashboard({super.key});

  @override
  State<CourierDashboard> createState() => _CourierDashboardState();
}

class _CourierDashboardState extends State<CourierDashboard> {
  late final DashboardBloc _bloc;
  late final Future<UserProfile> _profile;

  @override
  void initState() {
    super.initState();
    final service = GetIt.I<CourierService>();
    _profile = service.getUserProfile();
    _bloc = DashboardBloc(DashboardLoadingState())
      ..add(const LoadApiEvent(false));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<DashboardBloc, DashboardState>(
        listener: (context, state) {
          if (state is DashboardFinishedState && state.withErrors) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage)),
            );
          }
        },
        builder: (context, state) {
          if (state is DashboardLoadingState) {
            return const Scaffold(body: BrandSkeleton(rows: 8));
          }
          if (state is! DashboardLoadedState) {
            return Scaffold(
              body: BrandErrorState(
                onRetry: () => _bloc.add(const LoadApiEvent(true)),
              ),
            );
          }
          return _DashboardContent(
            state: state,
            profile: _profile,
            onRefresh: () async => _bloc.add(const LoadApiEvent(true)),
            onPay: () => _bloc.add(OnlinePaymentRequestEvent(context)),
            onDelivery: () {
              final available = state.recepciones
                  .where((package) => package.disponible && !package.retenido)
                  .toList(growable: false);
              _bloc.add(SolicitarDomicilioEvent(context, available));
            },
          );
        },
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.state,
    required this.profile,
    required this.onRefresh,
    required this.onPay,
    required this.onDelivery,
  });

  final DashboardLoadedState state;
  final Future<UserProfile> profile;
  final Future<void> Function() onRefresh;
  final VoidCallback onPay;
  final VoidCallback onDelivery;

  @override
  Widget build(BuildContext context) {
    final config = GetIt.I<BrandConfig>();
    final capabilities = config.capabilities.resolve(state.empresa);
    final recent = state.recepciones.take(3).toList(growable: false);
    final unread = state.mensajes.where((message) => !message.read).length;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: FutureBuilder<UserProfile>(
                future: profile,
                builder: (context, snapshot) => BrandHeader(
                  greeting: snapshot.data?.nombre.isNotEmpty ?? false
                      ? snapshot.data!.nombre
                      : 'bienvenido'.tr(),
                  account: snapshot.data?.cuenta ?? '',
                  capabilities: capabilities,
                  points: capabilities.points ? state.puntos.balance : null,
                  unread: unread,
                  onMessages: () => context.push(AppRoutes.messages),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
              sliver: SliverList.list(
                children: [
                  if (state.banners.isNotEmpty) ...[
                    BannerCarousel(banners: state.banners, config: config),
                    const SizedBox(height: 20),
                  ],
                  QuickActionGrid(
                    actions: [
                      QuickAction(
                        label: 'recepciones'.tr(),
                        icon: Icons.inventory_2_outlined,
                        onTap: () => context.push(AppRoutes.receptions),
                      ),
                      QuickAction(
                        label: 'disponibles'.tr(),
                        icon: Icons.check_circle_outline,
                        onTap: () => context.push(AppRoutes.available),
                      ),
                      QuickAction(
                        label: 'rastrear_paquete'.tr(),
                        icon: Icons.location_searching,
                        onTap: () => context.push(AppRoutes.tracking),
                      ),
                      QuickAction(
                        label: 'crear_pre_alerta'.tr(),
                        icon: Icons.add_alert_outlined,
                        enabled: capabilities.prealerts,
                        onTap: () => context.push(AppRoutes.prealert),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Column(
                      children: [
                        GroupRow(
                          label: 'recepciones'.tr(),
                          count: state.recepcionesCount,
                          onTap: () => context.push(AppRoutes.receptions),
                        ),
                        GroupRow(
                          label: 'disponibles'.tr(),
                          count: state.disponiblesCount,
                          onTap: () => context.push(AppRoutes.available),
                        ),
                        GroupRow(
                          label: 'retenido'.tr(),
                          count: state.retenidosCount,
                          onTap: () => context.push(
                            '${AppRoutes.receptions}?retenido=true',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (capabilities.payments || capabilities.delivery) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        if (capabilities.payments)
                          FilledButton.icon(
                            onPressed: onPay,
                            icon: const Icon(Icons.payment_outlined),
                            label: Text('pagar_ahora'.tr()),
                          ),
                        if (capabilities.delivery)
                          OutlinedButton.icon(
                            onPressed:
                                state.disponiblesCount == 0 ? null : onDelivery,
                            icon: const Icon(Icons.local_shipping_outlined),
                            label: Text('solicitar_domicilio'.tr()),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'recepciones'.tr(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (recent.isEmpty)
                    const BrandEmptyState(messageKey: 'no_paquetes')
                  else
                    for (final package in recent) ...[
                      PackageCard(
                        package: package,
                        onTap: () => context.push(
                          AppRoutes.package(package.recepcionID),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
