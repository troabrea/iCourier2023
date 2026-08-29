import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../design_system/brand_foundations.dart';
import '../design_system/brand_states.dart';
import '../design_system/content_components.dart';
import '../design_system/core_components.dart';
import '../design_system/home_components.dart';
import '../design_system/motion_components.dart';
import '../design_system/overlay_components.dart';
import '../domain/package_stage.dart';
import '../helpers/contact_action.dart';
import '../navigation/app_routes.dart';
import '../services/app_events.dart';
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
  late Future<UserProfile> _profile;
  late final Event<LoginChanged> _loginChanges;
  late final Event<UnreadMessagesChanged> _unreadMessagesChanged;
  int? _unreadCount;

  /// Last screen we had. A refresh runs through the loading state, and holding
  /// on to this keeps that from blanking the dashboard.
  DashboardLoadedState? _loaded;

  @override
  void initState() {
    super.initState();
    final service = GetIt.I<CourierService>();
    _unreadMessagesChanged = GetIt.I<Event<UnreadMessagesChanged>>()
      ..subscribe(_onUnreadMessagesChanged);
    _loginChanges = GetIt.I<Event<LoginChanged>>()..subscribe(_onLoginChanged);
    _profile = service.getUserProfile();
    _bloc = DashboardBloc(DashboardLoadingState())
      ..add(const LoadApiEvent(false));
  }

  @override
  void dispose() {
    _unreadMessagesChanged.unsubscribe(_onUnreadMessagesChanged);
    _loginChanges.unsubscribe(_onLoginChanged);
    _bloc.close();
    super.dispose();
  }

  void _onUnreadMessagesChanged(UnreadMessagesChanged? change) {
    if (change == null || !mounted) {
      return;
    }
    setState(() => _unreadCount = change.unreadCount);
  }

  void _onLoginChanged(LoginChanged? change) {
    if (change == null || !change.loggedIn || !mounted) {
      return;
    }
    setState(() {
      _loaded = null;
      _unreadCount = null;
      _profile = GetIt.I<CourierService>().getUserProfile();
    });
    _bloc.add(const LoadApiEvent(false));
  }

  /// Runs a reload and completes when it lands.
  ///
  /// Adding the event only queues it, so returning straight away would report
  /// success before anything had happened.
  Future<void> _refresh() async {
    _bloc.add(const LoadApiEvent(true));
    try {
      await _bloc.stream
          .firstWhere((state) => state is! DashboardLoadingState)
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      // Let go of the indicator even if the reload never reports back.
    }
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
          if (state is DashboardLoadedState) {
            _loaded = state;
          }
          // A refresh reloads through the same loading state as a cold start.
          // Replacing the screen with placeholders would throw away the header
          // and everything under it for a second; the card's own spinner says
          // work is happening, so the last screen stays put.
          final loaded = state is DashboardLoadedState ? state : _loaded;
          if (loaded == null) {
            if (state is DashboardLoadingState) {
              return Scaffold(
                backgroundColor: tokens.bg,
                body: const BrandSkeleton(rows: 8),
              );
            }
            return Scaffold(
              backgroundColor: tokens.bg,
              body: BrandErrorState(
                onRetry: () => _bloc.add(const LoadApiEvent(true)),
              ),
            );
          }
          return _DashboardContent(
            state: loaded,
            unread: _unreadCount ??
                loaded.mensajes.where((message) => !message.read).length,
            profile: _profile,
            refreshing: state is DashboardLoadingState,
            onRefresh: _refresh,
            onPay: () => _bloc.add(OnlinePaymentRequestEvent(context)),
            onPickup: () => _bloc.add(NotificarRetiroEvent(context)),
            onDelivery: () {
              final available = loaded.recepciones
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
    required this.unread,
    required this.profile,
    required this.refreshing,
    required this.onRefresh,
    required this.onPay,
    required this.onPickup,
    required this.onDelivery,
  });

  final DashboardLoadedState state;
  final int unread;
  final Future<UserProfile> profile;

  /// A reload is in flight over the screen we are already showing.
  final bool refreshing;
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
    _collapse.value = ((notification.metrics.pixels - (handoff - fade)) / fade)
        .clamp(0.0, 1.0);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final tokens = context.brand;
    final config = GetIt.I<BrandConfig>();
    final capabilities = config.capabilities.resolve(state.empresa);
    final unread = widget.unread;

    return Scaffold(
      backgroundColor: tokens.bg,
      // No pull gesture: the card carries a refresh button, and two ways to do
      // the same thing means one of them is always the one nobody finds.
      body: FutureBuilder<UserProfile>(
        future: widget.profile,
        builder: (context, snapshot) {
          final userProfile = snapshot.data;
          // The assistant is a paid module. When this courier does not have
          // it, the header position goes back to the branch contact channel it
          // held before, instead of leading nowhere.
          final assistant = state.empresa.hasAssistantModule;
          final channel = assistant ? null : resolveContactChannel(userProfile);
          final onContact = assistant
              ? () => context.push(AppRoutes.assistant)
              : (channel == null ? null : () => channel.open());
          final contactMark = assistant ? _assistantMark(context) : null;
          final pending = _pending();
          final banner = state.banners.isEmpty
              ? null
              : BannerCarousel(banners: state.banners, config: config);
          final actions = BrandHeaderActions(
            unread: unread,
            onContact: onContact,
            contactMark: contactMark,
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
              BrandManifestReveal(
                duration: const Duration(milliseconds: 420),
                child: BrandHeader(
                  key: _panelKey,
                  greeting: _firstName(userProfile),
                  accountName: userProfile?.nombre ?? '',
                  account: userProfile?.cuenta ?? '',
                  photoUrl: userProfile?.fotoPerfilUrl ?? '',
                  capabilities: capabilities,
                  unread: unread,
                  onAccounts: userProfile == null
                      ? null
                      : () => showBrandSheet<void>(
                            context,
                            scrollable: true,
                            child: CuentasUsuario(userProfile: userProfile),
                          ),
                  onContact: onContact,
                  contactMark: contactMark,
                  onCarnet: () => context.push(AppRoutes.idCard),
                  onMessages: () => context.push(AppRoutes.messages),
                ),
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
                    BrandManifestReveal(
                      delay: brandManifestDelay(1),
                      child: _statusCard(
                        context,
                        capabilities,
                        userProfile,
                        pending,
                        banner,
                      ),
                    ),
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
                          BrandManifestReveal(
                            delay: brandManifestDelay(2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (capabilities.prealerts)
                                  QuickActionList(
                                    actions: [
                                      QuickAction(
                                        label: 'crear_prealerta'
                                            .tr()
                                            .replaceAll('\n', ' '),
                                        icon: BrandIcons.prealert,
                                        onTap: () => context.push(
                                          AppRoutes.newPrealert,
                                        ),
                                      ),
                                    ],
                                  ),
                                BrandSectionLabel('mas_acciones'.tr()),
                                AdaptiveQuickActions(
                                  room: _roomForSecondaryActions(
                                    context,
                                    groups: pending,
                                    hasBanner: state.banners.isNotEmpty,
                                    hasPrimaryAction: capabilities.prealerts,
                                  ),
                                  actions: [
                                    QuickAction(
                                      label: 'ver_prealertas'
                                          .tr()
                                          .replaceAll('\n', ' '),
                                      icon: BrandIcons.receptions,
                                      enabled: capabilities.prealerts,
                                      onTap: () =>
                                          context.push(AppRoutes.prealert),
                                    ),
                                    QuickAction(
                                      label: 'rastrear_paquete'
                                          .tr()
                                          .replaceAll('\n', ' '),
                                      icon: BrandIcons.track,
                                      onTap: () =>
                                          context.push(AppRoutes.tracking),
                                    ),
                                    QuickAction(
                                      label: 'consulta_historica'
                                          .tr()
                                          .replaceAll('\n', ' '),
                                      icon: BrandIcons.history,
                                      onTap: () =>
                                          context.push(AppRoutes.history),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
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

  /// Vertical space the quick actions may take on the first screen.
  ///
  /// Budgeted rather than measured: every piece that outranks them declares its
  /// own height, so the answer is known while building instead of after a
  /// layout pass, and it cannot oscillate. A short answer only folds the rows
  /// behind a button — nothing is lost either way.
  double _roomForSecondaryActions(
    BuildContext context, {
    required List<({Recepcion package, PackageStage stage})> groups,
    required bool hasBanner,
    required bool hasPrimaryAction,
  }) {
    final stages = groups.map((entry) => entry.stage).toSet();
    final width = MediaQuery.sizeOf(context).width - BrandSpace.lg * 2;
    final reserved = MediaQuery.paddingOf(context).top +
        ScreenHeader.tabBandHeight +
        HomeStatusCard.heightFor(
          stageCount: stages.length,
          withActions: stages.contains(PackageStage.disponible),
          bannerHeight: hasBanner ? expectedBannerHeight(context, width) : 0,
        ) +
        BrandTabBar.height +
        // Section label and the air around it.
        44 +
        // Creating a pre-alert never folds, so secondary actions only receive
        // the room left after its dedicated row.
        (hasPrimaryAction ? QuickActionList.heightFor(1) : 0);
    return MediaQuery.sizeOf(context).height - reserved;
  }

  /// The home card: the count, then every state that holds a package.
  ///
  /// With nothing pending it invites a first order rather than reporting a
  /// zero.
  Widget _statusCard(
    BuildContext context,
    BrandCapabilities capabilities,
    UserProfile? profile,
    List<({Recepcion package, PackageStage stage})> pending,
    Widget? banner,
  ) {
    if (pending.isEmpty) {
      return HomeStatusCard(
        banner: banner,
        onShowAddress: () => context.push(AppRoutes.idCard),
        onRefresh: widget.onRefresh,
        refreshing: widget.refreshing,
      );
    }

    final byStage = <PackageStage, List<Recepcion>>{};
    for (final entry in pending) {
      (byStage[entry.stage] ??= <Recepcion>[]).add(entry.package);
    }

    return HomeStatusCard(
      banner: banner,
      total: pending.length,
      onOpenAll: () => context.push(AppRoutes.receptions),
      onRefresh: widget.onRefresh,
      refreshing: widget.refreshing,
      groups: [
        for (final stage in _stageOrder)
          if ((byStage[stage] ?? const <Recepcion>[]).isNotEmpty)
            _group(context, capabilities, stage, byStage[stage]!),
      ],
    );
  }

  /// What the customer can collect leads; the rest follow the journey.
  static const _stageOrder = <PackageStage>[
    PackageStage.disponible,
    PackageStage.origen,
    PackageStage.ruta,
    PackageStage.destino,
    PackageStage.entregado,
  ];

  HomeStageGroup _group(
    BuildContext context,
    BrandCapabilities capabilities,
    PackageStage stage,
    List<Recepcion> packages,
  ) {
    // Only what the customer can collect carries actions; everything else is
    // still travelling and there is nothing to do about it yet.
    final ready = stage == PackageStage.disponible;
    final held = packages.where((package) => package.retenido).toList();
    return HomeStageGroup(
      stage: stage,
      count: packages.length,
      contents: _contents(packages),
      onOpen: () => context.push(
        ready
            ? AppRoutes.available
            : '${AppRoutes.receptions}?estado=${stage.name}',
      ),
      retained: held.isEmpty
          ? null
          : HomeRetainedGroup(
              count: held.length,
              contents: _contents(held),
              onOpen: () => context.push(
                '${AppRoutes.receptions}'
                '?retenido=true&estado=${stage.name}',
              ),
            ),
      onPickup: ready ? widget.onPickup : null,
      onDelivery: ready && capabilities.delivery ? widget.onDelivery : null,
      onPay: ready && capabilities.payments ? widget.onPay : null,
    );
  }

  /// What the packages in a state actually are, without repeating a description
  /// the customer would read twice.
  String _contents(List<Recepcion> packages) {
    final seen = <String>{};
    for (final package in packages) {
      final label = package.contenido.trim().isEmpty
          ? package.suplidor.trim()
          : package.contenido.trim();
      if (label.isNotEmpty) {
        seen.add(label);
      }
    }
    return seen.join(' · ');
  }

  /// The assistant's own mark, so the header button shows what it opens.
  ///
  /// This position used to carry the branch WhatsApp. Home is behind the
  /// session, so the assistant is always available here; WhatsApp is one tap
  /// deeper, in the assistant's own header.
  Widget _assistantMark(BuildContext context) => BrandGlyph(
        BrandIcons.assistant,
        color: context.brand.onPrimary,
        size: 18,
      );

  String _firstName(UserProfile? profile) {
    final name = profile?.nombre.trim() ?? '';
    if (name.isEmpty) {
      return 'bienvenido'.tr();
    }
    return name.split(RegExp(r'[\s,]+')).first;
  }
}
