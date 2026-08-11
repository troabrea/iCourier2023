import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design_system/brand_foundations.dart';
import '../design_system/brand_states.dart';
import '../design_system/content_components.dart';
import '../design_system/core_components.dart';
import '../helpers/contact_action.dart';
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
    _bloc = ServiciosBloc(GetIt.I<CourierService>())..add(const LoadApiEvent());
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
              trailing: const BrandContactAction(),
            )
          : ScreenHeader(
              title: 'nuestros_servicios'.tr(),
              onBack: context.popOrHome,
              trailing: const BrandContactAction(),
            ),
      body: BlocProvider.value(
        value: _bloc,
        child: BlocBuilder<ServiciosBloc, ServiciosState>(
          builder: (context, state) {
            if (state is ServiciosLoadingState) {
              return const BrandSkeleton();
            }
            if (state is ServiciosErrorState) {
              return BrandErrorState(
                onRetry: () => _bloc.add(const LoadApiEvent(ignoreCache: true)),
              );
            }
            if (state is! ServiciosLoadedState) {
              return const BrandEmptyState(
                messageKey: 'no_resultados',
                glyph: BrandIcons.services,
              );
            }
            if (state.servicios.isEmpty) {
              return const BrandEmptyState(
                messageKey: 'no_resultados',
                glyph: BrandIcons.services,
              );
            }
            final showBanners = widget.isTabRoot && state.banners.isNotEmpty;
            return RefreshIndicator(
              onRefresh: () async =>
                  _bloc.add(const LoadApiEvent(ignoreCache: true)),
              child: ListView(
                padding: EdgeInsets.only(
                  bottom: BrandTabBar.height,
                  top: showBanners ? 0 : BrandSpace.md,
                ),
                children: [
                  if (showBanners)
                    BannerCarousel(
                      banners: state.banners,
                      config: GetIt.I<BrandConfig>(),
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
                        for (var index = 0;
                            index < state.servicios.length;
                            index++)
                          _serviceCard(state.servicios[index], index),
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
    final url = _serviceUrl(service.url);
    return ServiceCard(
      title: service.titulo,
      description: service.resumen,
      glyph: _glyphs[index % _glyphs.length],
      onTap: url == null
          ? null
          : () => launchUrl(url, mode: LaunchMode.externalApplication),
    );
  }

  Uri? _serviceUrl(Object? raw) {
    final uri = Uri.tryParse(raw?.toString() ?? '');
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
      return null;
    }
    return uri;
  }
}
