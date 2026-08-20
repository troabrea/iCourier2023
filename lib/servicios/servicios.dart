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
    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: widget.isTabRoot
          ? ScreenHeader.tab(
              title: 'nuestros_servicios'.tr(),
              trailing: const BrandAssistantAction(),
            )
          : ScreenHeader(
              title: 'nuestros_servicios'.tr(),
              onBack: context.popOrHome,
              trailing: const BrandAssistantAction(),
            ),
      body: BlocProvider.value(
        value: _bloc,
        child: BlocBuilder<ServiciosBloc, ServiciosState>(
          builder: (context, state) {
            if (state is ServiciosLoadingState) {
              return const BrandSkeleton();
            }
            if (state is ServiciosErrorState) {
              return BrandErrorState(onRetry: _refresh);
            }
            if (state is! ServiciosLoadedState) {
              return const SizedBox.shrink();
            }
            final showBanners = widget.isTabRoot && state.banners.isNotEmpty;
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  bottom: BrandTabBar.height,
                  top: showBanners ? 0 : BrandSpace.md,
                ),
                children: [
                  if (showBanners)
                    BrandManifestReveal(
                      child: BannerCarousel(
                        banners: state.banners,
                        config: GetIt.I<BrandConfig>(),
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
                        if (state.servicios.isEmpty)
                          BrandManifestReveal(
                            child: BrandEmptyState(
                              messageKey: 'servicios_vacios',
                              glyph: BrandIcons.services,
                              actionLabel: 'actualizar'.tr(),
                              onAction: _refresh,
                            ),
                          )
                        else ...[
                          if (!widget.isTabRoot) ...[
                            BrandManifestReveal(
                              child: _ServicesGuide(
                                count: state.servicios.length,
                              ),
                            ),
                            const SizedBox(height: BrandSpace.md),
                          ],
                          for (var index = 0;
                              index < state.servicios.length;
                              index++)
                            BrandManifestReveal(
                              key: ValueKey(
                                state.servicios[index].registroId,
                              ),
                              delay: brandManifestDelay(
                                index,
                                startMilliseconds: 90,
                              ),
                              child: _serviceCard(
                                state.servicios[index],
                                index,
                              ),
                            ),
                        ],
                      ],
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
