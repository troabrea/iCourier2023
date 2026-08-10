import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design_system/brand_foundations.dart';
import '../design_system/brand_states.dart';
import '../design_system/content_components.dart';
import '../design_system/core_components.dart';
import '../services/courier_service.dart';
import '../theme/brand_tokens.dart';
import 'bloc/servicios_bloc.dart';

class ServiciosPage extends StatefulWidget {
  const ServiciosPage({super.key});

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
      appBar: ScreenHeader(
        title: 'nuestros_servicios'.tr(),
        onBack: context.canPop() ? context.pop : null,
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
            return RefreshIndicator(
              onRefresh: () async =>
                  _bloc.add(const LoadApiEvent(ignoreCache: true)),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  BrandSpace.lg,
                  BrandSpace.md,
                  BrandSpace.lg,
                  BrandTabBar.height,
                ),
                itemCount: state.servicios.length,
                itemBuilder: (context, index) {
                  final service = state.servicios[index];
                  final url = _serviceUrl(service.url);
                  return ServiceCard(
                    title: service.titulo,
                    description: service.resumen,
                    glyph: _glyphs[index % _glyphs.length],
                    onTap: url == null
                        ? null
                        : () => launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            ),
                  );
                },
              ),
            );
          },
        ),
      ),
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
