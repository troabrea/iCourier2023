import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../design_system/brand_foundations.dart';
import '../design_system/brand_states.dart';
import '../design_system/content_components.dart';
import '../design_system/core_components.dart';
import '../design_system/home_components.dart';
import '../design_system/overlay_components.dart';
import '../helpers/contact_action.dart';
import '../domain/package_stage.dart';
import '../navigation/app_routes.dart';
import '../services/courier_service.dart';
import '../services/model/login_model.dart';
import '../services/model/recepcion.dart';
import '../theme/brand_config.dart';
import '../theme/brand_tokens.dart';
import 'bloc/dashboard_bloc.dart';
import 'cuentas_usuario.dart';

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
    final tokens = context.brand;
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
            return Scaffold(
              backgroundColor: tokens.bg,
              body: const BrandSkeleton(rows: 8),
            );
          }
          if (state is! DashboardLoadedState) {
            return Scaffold(
              backgroundColor: tokens.bg,
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
            onPickup: () => _bloc.add(NotificarRetiroEvent(context)),
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
    required this.onPickup,
    required this.onDelivery,
  });

  final DashboardLoadedState state;
  final Future<UserProfile> profile;
  final Future<void> Function() onRefresh;
  final VoidCallback onPay;
  final VoidCallback onPickup;
  final VoidCallback onDelivery;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final config = GetIt.I<BrandConfig>();
    final capabilities = config.capabilities.resolve(state.empresa);
    final unread = state.mensajes.where((message) => !message.read).length;

    return Scaffold(
      backgroundColor: tokens.bg,
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: FutureBuilder<UserProfile>(
          future: profile,
          builder: (context, snapshot) {
            final userProfile = snapshot.data;
            // A single scroll list, not slivers: the hero card is pulled up
            // onto the header and a sliver boundary would clip it.
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                BrandHeader(
                  greeting: _firstName(userProfile),
                  accountName: userProfile?.nombre ?? '',
                  account: userProfile?.cuenta ?? '',
                  capabilities: capabilities,
                  unread: unread,
                  onAccounts: userProfile == null
                      ? null
                      : () => showBrandSheet<void>(
                            context,
                            scrollable: true,
                            child: CuentasUsuario(userProfile: userProfile),
                          ),
                  onContact: _contact(userProfile)?.open,
                  contactIcon: _contact(userProfile)?.icon ??
                      Icons.chat_bubble_outline,
                  onCarnet: () => context.push(AppRoutes.idCard),
                  onMessages: () => context.push(AppRoutes.messages),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    BrandSpace.lg,
                    0,
                    BrandSpace.lg,
                    BrandTabBar.height,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _statusCard(context, capabilities, userProfile),
                      // The hero card is pulled 30 up onto the header, so the
                      // flow below reclaims that space.
                      Transform.translate(
                        offset: const Offset(0, -30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // La tarjeta héroe termina justo encima; sin este
                            // aire las dos superficies se leen como una sola.
                            const SizedBox(height: 14),
                            ReceptionsGroupCard(
                              total: state.recepcionesCount,
                              children: _groups(context, state.recepciones),
                            ),
                            BrandSectionLabel('acciones_rapidas'.tr()),
                            QuickActionGrid(
                              actions: [
                                QuickAction(
                                  label: 'crear_prealerta'
                                      .tr()
                                      .replaceAll('\n', ' '),
                                  icon: BrandIcons.prealert,
                                  enabled: capabilities.prealerts,
                                  onTap: () =>
                                      context.push(AppRoutes.newPrealert),
                                ),
                                QuickAction(
                                  label: 'ver_prealertas'
                                      .tr()
                                      .replaceAll('\n', ' '),
                                  icon: BrandIcons.receptions,
                                  enabled: capabilities.prealerts,
                                  onTap: () => context.push(AppRoutes.prealert),
                                ),
                                QuickAction(
                                  label: 'rastrear_paquete'
                                      .tr()
                                      .replaceAll('\n', ' '),
                                  icon: BrandIcons.track,
                                  onTap: () => context.push(AppRoutes.tracking),
                                ),
                                QuickAction(
                                  label: 'consulta_historica'
                                      .tr()
                                      .replaceAll('\n', ' '),
                                  icon: BrandIcons.history,
                                  onTap: () => context.push(AppRoutes.history),
                                ),
                              ],
                            ),
                            if (state.banners.isNotEmpty) ...[
                              const SizedBox(height: BrandSpace.md),
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(tokens.radiusMd),
                                child: BannerCarousel(
                                  banners: state.banners,
                                  config: config,
                                  height: 180,
                                ),
                              ),
                            ],
                            if (capabilities.points) ...[
                              const SizedBox(height: BrandSpace.md),
                              PointsCard(
                                label: config.loyaltyLabel,
                                balance: '${state.puntos.balance}',
                                onRedeem: capabilities.payments ? onPay : null,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Chooses what the home card should lead with.
  ///
  /// Something ready to collect always wins; otherwise the card reports what
  /// is closest to arriving, and with nothing at all it invites a first order.
  Widget _statusCard(
    BuildContext context,
    BrandCapabilities capabilities,
    UserProfile? profile,
  ) {
    if (state.disponiblesCount > 0) {
      return HomeStatusCard(
        status: HomeStatus.ready,
        count: state.disponiblesCount,
        total: state.montoTotal.toStringAsFixed(2),
        currency: r'$',
        branch: profile?.nombreSucursal ?? '',
        onTap: () => context.push(AppRoutes.available),
        onPickup: onPickup,
        onDelivery: capabilities.delivery ? onDelivery : null,
      );
    }

    final inTransit = <({Recepcion package, PackageStage stage})>[];
    for (final package in state.recepciones) {
      final stage = PackageStatusMapper.map(
        status: package.estatus,
        isAvailable: package.disponible,
        progress: package.progreso,
      ).stage;
      if (stage != PackageStage.entregado && stage != PackageStage.disponible) {
        inTransit.add((package: package, stage: stage));
      }
    }

    if (inTransit.isEmpty) {
      return HomeStatusCard(
        status: HomeStatus.empty,
        onShowAddress: () => context.push(AppRoutes.idCard),
      );
    }

    // The nearest one is simply the furthest along its four macro steps.
    inTransit.sort((a, b) => b.stage.index.compareTo(a.stage.index));
    final next = inTransit.first;
    return HomeStatusCard(
      status: HomeStatus.onTheWay,
      count: inTransit.length,
      nextContent: next.package.contenido.isEmpty
          ? next.package.suplidor
          : next.package.contenido,
      nextStage: next.stage,
      nextRetained: next.package.retenido,
      onTap: () => context.push(AppRoutes.receptions),
    );
  }

  /// Receptions grouped by macro state; empty groups are not rendered.
  List<Widget> _groups(BuildContext context, List<Recepcion> receptions) {
    final counts = <PackageStage, int>{};
    for (final package in receptions) {
      final stage = PackageStatusMapper.map(
        status: package.estatus,
        isAvailable: package.disponible,
        progress: package.progreso,
      ).stage;
      counts[stage] = (counts[stage] ?? 0) + 1;
    }
    return [
      for (final stage in PackageStage.values)
        GroupRow(
          label: _stageLabel(stage).tr(),
          count: counts[stage] ?? 0,
          onTap: () => context.push(
            '${AppRoutes.receptions}?estado=${stage.name}',
          ),
        ),
    ];
  }

  /// Same resolution the tab headers use, so both open the same channel.
  ({IconData icon, Future<void> Function() open})? _contact(
    UserProfile? profile,
  ) =>
      resolveContactChannel(profile);

  String _firstName(UserProfile? profile) {
    final name = profile?.nombre.trim() ?? '';
    if (name.isEmpty) {
      return 'bienvenido'.tr();
    }
    return name.split(RegExp(r'[\s,]+')).first;
  }
}

String _stageLabel(PackageStage stage) => switch (stage) {
      PackageStage.origen => 'recibido',
      PackageStage.ruta => 'en_ruta',
      PackageStage.destino => 'en_destino',
      PackageStage.disponible => 'disponibles',
      PackageStage.entregado => 'entregado',
    };
