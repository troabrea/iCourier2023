import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design_system/brand_states.dart';
import '../design_system/content_components.dart';
import '../design_system/core_components.dart';
import '../services/courier_service.dart';
import '../theme/brand_config.dart';
import 'bloc/servicios_bloc.dart';

class ServiciosPage extends StatefulWidget {
  const ServiciosPage({super.key});

  @override
  State<ServiciosPage> createState() => _ServiciosPageState();
}

class _ServiciosPageState extends State<ServiciosPage> {
  late final ServiciosBloc _bloc;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _bloc = ServiciosBloc(GetIt.I<CourierService>())..add(const LoadApiEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ScreenHeader(title: 'servicios'.tr()),
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
              return const BrandEmptyState(messageKey: 'no_resultados');
            }
            final services = state.servicios.where((service) {
              final query = _query.toLowerCase();
              return query.isEmpty ||
                  service.titulo.toLowerCase().contains(query) ||
                  service.resumen.toLowerCase().contains(query);
            }).toList(growable: false);
            return RefreshIndicator(
              onRefresh: () async =>
                  _bloc.add(const LoadApiEvent(ignoreCache: true)),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  if (state.banners.isNotEmpty) ...[
                    BannerCarousel(
                      banners: state.banners,
                      config: GetIt.I<BrandConfig>(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  SearchBar(
                    controller: _searchController,
                    hintText: 'buscar'.tr(),
                    leading: const Icon(Icons.search),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 16),
                  if (services.isEmpty)
                    const BrandEmptyState(messageKey: 'no_resultados')
                  else
                    for (final service in services) ...[
                      ServiceCard(
                        title: service.titulo,
                        description: service.resumen,
                        onTap: _serviceUrl(service.url) == null
                            ? null
                            : () => launchUrl(
                                  _serviceUrl(service.url)!,
                                  mode: LaunchMode.externalApplication,
                                ),
                      ),
                      const SizedBox(height: 12),
                    ],
                ],
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
