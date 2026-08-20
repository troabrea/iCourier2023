import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../asistente/assistant_action.dart';
import '../design_system/brand_foundations.dart';
import '../design_system/brand_states.dart';
import '../design_system/content_components.dart';
import '../design_system/core_components.dart';
import '../design_system/motion_components.dart';
import '../helpers/social_media_links.dart';
import '../navigation/app_routes.dart';
import '../services/courier_service.dart';
import '../theme/brand_config.dart';
import '../theme/brand_tokens.dart';
import 'bloc/noticias_bloc.dart';

class NoticiasPage extends StatefulWidget {
  const NoticiasPage({super.key, this.isTabRoot = false});

  /// True when the brand gave this module a permanent tab. A tab root carries
  /// the banners and has nothing to go back to; reached from "más" it is a
  /// stacked screen, so it shows a back button and leaves the banners to
  /// whichever module does own a tab.
  final bool isTabRoot;

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
    final tokens = context.brand;
    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: widget.isTabRoot
          ? ScreenHeader.tab(
              title: 'noticias'.tr(),
              trailing: const BrandAssistantAction(),
            )
          : ScreenHeader(
              title: 'noticias'.tr(),
              onBack: context.popOrHome,
              trailing: const BrandAssistantAction(),
            ),
      body: BlocProvider.value(
        value: _bloc,
        child: BlocBuilder<NoticiasBloc, NoticiasState>(
          builder: (context, state) {
            if (state is NoticiasLoadingState) {
              return const BrandSkeleton();
            }
            if (state is NoticiasErrorState) {
              return BrandErrorState(onRetry: _refresh);
            }
            if (state is! NoticiasLoadedState) {
              return const BrandEmptyState(
                messageKey: 'no_resultados',
                glyph: BrandIcons.news,
              );
            }
            final showBanners = widget.isTabRoot && state.banners.isNotEmpty;
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: BrandTabBar.height),
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
                      widget.isTabRoot ? BrandSpace.md : BrandSpace.lg,
                      BrandSpace.lg,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (state.noticias.isEmpty)
                          BrandManifestReveal(
                            child: BrandEmptyState(
                              messageKey: 'noticias_vacias',
                              glyph: BrandIcons.news,
                              actionLabel: 'actualizar'.tr(),
                              onAction: _refresh,
                            ),
                          )
                        else
                          for (var index = 0;
                              index < state.noticias.length;
                              index++)
                            BrandManifestReveal(
                              key: ValueKey(
                                state.noticias[index].heroIdentity,
                              ),
                              delay: brandManifestDelay(
                                index,
                                startMilliseconds: 45,
                              ),
                              child: NewsCard(
                                news: state.noticias[index],
                                onTap: () => context.push(
                                  AppRoutes.newsDetail(
                                    state.noticias[index].heroIdentity,
                                  ),
                                  extra: state.noticias[index],
                                ),
                              ),
                            ),
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

  Future<void> _refresh() async {
    final completed = Completer<void>();
    _bloc.add(LoadApiEvent(ignoreCache: true, completed: completed));
    await completed.future;
  }
}
