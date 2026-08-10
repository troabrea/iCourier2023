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
import '../theme/brand_config.dart';
import 'bloc/noticias_bloc.dart';

class NoticiasPage extends StatefulWidget {
  const NoticiasPage({super.key});

  @override
  State<NoticiasPage> createState() => _NoticiasPageState();
}

class _NoticiasPageState extends State<NoticiasPage> {
  late final NoticiasBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = NoticiasBloc(GetIt.I<CourierService>())..add(const LoadApiEvent());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ScreenHeader(title: 'noticias'.tr()),
      body: BlocProvider.value(
        value: _bloc,
        child: BlocBuilder<NoticiasBloc, NoticiasState>(
          builder: (context, state) {
            if (state is NoticiasLoadingState) {
              return const BrandSkeleton();
            }
            if (state is NoticiasErrorState) {
              return BrandErrorState(
                onRetry: () => _bloc.add(
                  const LoadApiEvent(ignoreCache: true),
                ),
              );
            }
            if (state is! NoticiasLoadedState) {
              return const BrandEmptyState(messageKey: 'no_resultados');
            }
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
                    const SizedBox(height: 20),
                  ],
                  if (state.noticias.isEmpty)
                    const BrandEmptyState(messageKey: 'no_resultados')
                  else
                    for (final news in state.noticias) ...[
                      NewsCard(
                        news: news,
                        onTap: () => context.push(
                          AppRoutes.newsDetail(news.registroId),
                          extra: news,
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
}
