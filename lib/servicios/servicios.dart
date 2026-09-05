import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';

import '../asistente/assistant_action.dart';
import '../design_system/brand_foundations.dart';
import '../design_system/brand_states.dart';
import '../design_system/content_components.dart';
import '../design_system/core_components.dart';
import '../design_system/motion_components.dart';
import '../helpers/social_media_links.dart';
import '../navigation/app_routes.dart';
import '../services/courier_service.dart';
import '../services/model/servicio.dart';
import '../theme/brand_config.dart';
import '../theme/brand_tokens.dart';
import 'bloc/servicios_bloc.dart';

class ServiciosPage extends StatefulWidget {
  const ServiciosPage({super.key, this.isTabRoot = false});

  /// See [NoticiasPage.isTabRoot]: a tab root owns the banners and has no back
  /// button; the same screen reached from "más" is stacked.
  final bool isTabRoot;

  @override
  State<ServiciosPage> createState() => _ServiciosPageState();
}

class _ServiciosPageState extends State<ServiciosPage> {
  late final ServiciosBloc _bloc;
  String _query = '';

  /// Glyphs cycle through the service icon set so each card reads distinctly
  /// without the backend having to supply one.
  static const _glyphs = [
    BrandIcons.receptions,
    BrandIcons.shipped,
    BrandIcons.atDestination,
    BrandIcons.missingInvoice,
    BrandIcons.track,
  ];

  @override
  void initState() {
    super.initState();
    _bloc = ServiciosBloc(
      GetIt.I<CourierService>(),
      loadBanners: widget.isTabRoot,
    )..add(const LoadApiEvent());
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
      child: BlocBuilder<ServiciosBloc, ServiciosState>(
        builder: (context, state) {
          final showBanners = widget.isTabRoot &&
              state is ServiciosLoadedState &&
              state.banners.isNotEmpty;
          return Scaffold(
            backgroundColor: tokens.bg,
            // The banner runs edge to edge, so it is the piece that fills the
            // skirt's corners: the list starts under the header and lifts the
            // banner into the curve instead of leaving a pale wedge each side.
            extendBodyBehindAppBar: showBanners,
            appBar: widget.isTabRoot
                ? ScreenHeader.tab(
                    title: 'nuestros_servicios'.tr(),
                    onSearchChanged: _updateQuery,
                    searchHint: 'buscar_servicios'.tr(),
                    trailing: const BrandAssistantAction(),
                  )
                : ScreenHeader(
                    title: 'nuestros_servicios'.tr(),
                    onBack: context.popOrHome,
                    onSearchChanged: _updateQuery,
                    searchHint: 'buscar_servicios'.tr(),
                    trailing: const BrandAssistantAction(),
                  ),
            body: _body(context, state, showBanners),
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context, ServiciosState state, bool showBanners) {
    if (state is ServiciosLoadingState) {
      return const BrandSkeleton();
    }
    if (state is ServiciosErrorState) {
      return BrandErrorState(onRetry: _refresh);
    }
    if (state is! ServiciosLoadedState) {
      return const SizedBox.shrink();
    }
    final normalizedQuery = _query.toLowerCase();
    final services = [
      for (final (index, service) in state.servicios.indexed)
        if (normalizedQuery.isEmpty ||
            service.titulo.toLowerCase().contains(normalizedQuery) ||
            service.resumen.toLowerCase().contains(normalizedQuery))
          (service: service, glyphIndex: index),
    ];
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.only(
          bottom: BrandTabBar.height,
          top: showBanners
              ? ScreenHeader.tabHeight(context) - ScreenHeader.skirtOverlap
              : BrandSpace.md,
        ),
        children: [
          if (showBanners)
            BrandManifestReveal(
              child: BannerCarousel(
                banners: state.banners,
                config: GetIt.I<BrandConfig>(),
                // Fills the skirt's corners from the banner's own backdrop
                // instead of lifting the artwork into the curve and losing its
                // top strip.
                topBleed: ScreenHeader.skirtOverlap,
              ),
            ),
          if (showBanners)
            BrandManifestReveal(
              delay: const Duration(milliseconds: 70),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  BrandSpace.lg,
                  BrandSpace.xxs,
                  BrandSpace.lg,
                  0,
                ),
                child: SocialMediaLinks(
                  empresa: state.empresa,
                  userProfile: state.userProfile,
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              BrandSpace.lg,
              showBanners ? BrandSpace.md : 0,
              BrandSpace.lg,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (services.isEmpty)
                  BrandManifestReveal(
                    child: BrandEmptyState(
                      messageKey: normalizedQuery.isEmpty
                          ? 'servicios_vacios'
                          : 'sin_servicios_coincidentes',
                      glyph: BrandIcons.services,
                      actionLabel:
                          normalizedQuery.isEmpty ? 'actualizar'.tr() : null,
                      onAction: normalizedQuery.isEmpty ? _refresh : null,
                    ),
                  )
                else ...[
                  if (!widget.isTabRoot) ...[
                    BrandManifestReveal(
                      child: _ServicesGuide(
                        count: services.length,
                      ),
                    ),
                    const SizedBox(height: BrandSpace.md),
                  ],
                  for (var index = 0; index < services.length; index++)
                    BrandManifestReveal(
                      key: ValueKey(
                        services[index].service.registroId,
                      ),
                      delay: brandManifestDelay(
                        index,
                        startMilliseconds: 45,
                      ),
                      child: _serviceCard(
                        services[index].service,
                        services[index].glyphIndex,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _serviceCard(Servicio service, int index) {
    final url = service.externalDetailsUri;
    return ServiceCard(
      title: service.titulo,
      description: service.resumen,
      glyph: _glyphs[index % _glyphs.length],
      onOpenDetails: url == null ? null : () => _openServiceDetails(url),
    );
  }

  Future<void> _openServiceDetails(Uri url) async {
    var opened = false;
    try {
      opened = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    } on PlatformException {
      opened = false;
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('no_se_pudo_abrir_enlace'.tr())),
      );
    }
  }

  void _updateQuery(String value) {
    setState(() => _query = value.trim());
  }

  Future<void> _refresh() async {
    final completed = Completer<void>();
    _bloc.add(LoadApiEvent(ignoreCache: true, completed: completed));
    await completed.future;
  }
}

class _ServicesGuide extends StatelessWidget {
  const _ServicesGuide({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Semantics(
      container: true,
      child: Row(
        children: [
          const BrandGlyphTile(
            asset: BrandIcons.services,
            size: 44,
            glyphSize: 23,
          ),
          const SizedBox(width: BrandSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'servicios_guia'.tr(),
                  style: tokens.body(13, weight: FontWeight.w600, height: 1.35),
                ),
                const SizedBox(height: BrandSpace.xxs),
                Text(
                  'servicios_disponibles'.plural(count, args: ['$count']),
                  style: tokens.body(12, color: tokens.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
