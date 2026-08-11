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

class _DashboardContent extends StatefulWidget {
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
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  /// Measures the expanded panel so the hand-off point follows whatever height
  /// the brand's capabilities give it, instead of a guessed constant.
  final _panelKey = GlobalKey();

  /// How far the compact bar has taken over, 0 to 1. A notifier rather than
  /// state: only the bar listens, so scrolling never rebuilds the list.
  final _collapse = ValueNotifier<double>(0);

  @override
  void dispose() {
    _collapse.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth > 0) {
      return false;
    }
    final box = _panelKey.currentContext?.findRenderObject() as RenderBox?;
    final panelHeight = box?.size.height ?? 0;
    if (panelHeight <= 0) {
      return false;
    }
    // The bar appears just as the panel finishes leaving, so the two never
    // show the same identity at once.
    final barHeight =
        MediaQuery.paddingOf(context).top + ScreenHeader.tabBandHeight;
    final handoff = panelHeight - barHeight;
    const fade = 48.0;
    _collapse.value =
        ((notification.metrics.pixels - (handoff - fade)) / fade).clamp(0.0, 1.0);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final tokens = context.brand;
    final config = GetIt.I<BrandConfig>();
    final capabilities = config.capabilities.resolve(state.empresa);
    final unread = state.mensajes.where((message) => !message.read).length;

    return Scaffold(
      backgroundColor: tokens.bg,
      body: RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: FutureBuilder<UserProfile>(
          future: widget.profile,
          builder: (context, snapshot) {
            final userProfile = snapshot.data;
            final pending = _pending();
            final actions = BrandHeaderActions(
              unread: unread,
              onContact: _contact(userProfile)?.open,
              contactIcon:
                  _contact(userProfile)?.icon ?? Icons.chat_bubble_outline,
              onCarnet: () => context.push(AppRoutes.idCard),
              onMessages: () => context.push(AppRoutes.messages),
            );
            // A single scroll list, not slivers: the hero card is pulled up
            // onto the header and a sliver boundary would clip it. The bar the
            // panel collapses into therefore rides above the list rather than
            // being pinned by the viewport.
            final list = ListView(
              padding: EdgeInsets.zero,
              children: [
                BrandHeader(
                  key: _panelKey,
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
                      _statusCard(context, capabilities, userProfile, pending),
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
                              total: pending.length,
                              children: _groups(context, pending),
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
                                ),
                              ),
                            ],
                            if (capabilities.points) ...[
                              const SizedBox(height: BrandSpace.md),
                              PointsCard(
                                label: config.loyaltyLabel,
                                balance: '${state.puntos.balance}',
                                onRedeem:
                                    capabilities.payments ? widget.onPay : null,
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

            return NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: Stack(
                children: [
                  list,
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: ValueListenableBuilder<double>(
                      valueListenable: _collapse,
                      builder: (context, progress, child) => IgnorePointer(
                        ignoring: progress < 1,
                        child: Opacity(
                          opacity: progress,
                          // Slides the last few points into place so the bar
                          // arrives rather than blinking on.
                          child: Transform.translate(
                            offset: Offset(0, (progress - 1) * 8),
                            child: child,
                          ),
                        ),
                      ),
                      child: ScreenHeader.tab(
                        title: _firstName(userProfile),
                        trailing: actions,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Receptions the customer still has something to wait for, each with its
  /// macro stage.
  ///
  /// Delivered ones are dropped: nothing about them is pending, and counting
  /// them made the hero card say "no packages" while the group card underneath
  /// still reported one. Home now reads a single list; delivered receptions
  /// stay reachable from the history screen.
  List<({Recepcion package, PackageStage stage})> _pending() {
    final pending = <({Recepcion package, PackageStage stage})>[];
    for (final package in widget.state.recepciones) {
      var stage = PackageStatusMapper.map(
        status: package.estatus,
        isAvailable: package.disponible,
        progress: package.progreso,
      ).stage;
      if (stage == PackageStage.entregado) {
        continue;
      }
      // The operational status text can read "disponible" before the flag that
      // pickup and delivery act on catches up. The flag is the one that decides
      // whether the customer can actually collect, so it wins.
      if (stage == PackageStage.disponible && !package.disponible) {
        stage = PackageStage.destino;
      }
      pending.add((package: package, stage: stage));
    }
    return pending;
  }

  /// Chooses what the home card should lead with.
  ///
  /// Something ready to collect always wins; otherwise the card reports what
  /// is closest to arriving, and with nothing at all it invites a first order.
  Widget _statusCard(
    BuildContext context,
    BrandCapabilities capabilities,
    UserProfile? profile,
    List<({Recepcion package, PackageStage stage})> pending,
  ) {
    if (widget.state.disponiblesCount > 0) {
      return HomeStatusCard(
        status: HomeStatus.ready,
        count: widget.state.disponiblesCount,
        total: widget.state.montoTotal.toStringAsFixed(2),
        currency: r'$',
        branch: profile?.nombreSucursal ?? '',
        onTap: () => context.push(AppRoutes.available),
        onPickup: widget.onPickup,
        onDelivery: capabilities.delivery ? widget.onDelivery : null,
      );
    }

    if (pending.isEmpty) {
      return HomeStatusCard(
        status: HomeStatus.empty,
        onShowAddress: () => context.push(AppRoutes.idCard),
      );
    }

    // The nearest one is simply the furthest along its four macro steps.
    final inTransit = [...pending]
      ..sort((a, b) => b.stage.index.compareTo(a.stage.index));
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
  List<Widget> _groups(
    BuildContext context,
    List<({Recepcion package, PackageStage stage})> pending,
  ) {
    final counts = <PackageStage, int>{};
    for (final entry in pending) {
      counts[entry.stage] = (counts[entry.stage] ?? 0) + 1;
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
