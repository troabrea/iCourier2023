import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../design_system/brand_foundations.dart';
import '../design_system/brand_states.dart';
import '../design_system/core_components.dart';
import '../design_system/overlay_components.dart';
import '../helpers/social_media_links.dart';
import '../navigation/app_routes.dart';
import '../services/courier_service.dart';
import '../services/model/empresa.dart';
import '../services/model/login_model.dart';
import '../theme/brand_config.dart';
import '../theme/brand_tokens.dart';

typedef _MoreData = ({UserProfile profile, Empresa company, String version});

class AdicionalInfoPage extends StatefulWidget {
  const AdicionalInfoPage({super.key});

  @override
  State<AdicionalInfoPage> createState() => _AdicionalInfoPageState();
}

class _AdicionalInfoPageState extends State<AdicionalInfoPage> {
  late Future<_MoreData> _data;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: ScreenHeader.tab(title: 'informacion_adicional'.tr()),
      body: FutureBuilder<_MoreData>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return BrandErrorState(
              onRetry: () => setState(() => _data = _load()),
            );
          }
          if (!snapshot.hasData) {
            return const BrandSkeleton(rows: 7);
          }
          final data = snapshot.requireData;
          final config = GetIt.I<BrandConfig>();
          // A module that already owns a permanent tab must not be listed
          // again here: the row would duplicate the destination and, since a
          // tab lives in the shell, pushing it would fight the navigator.
          final tabs = config.navigation.tabs.toSet();
          final hasAbout = data.company.mision.isNotEmpty ||
              data.company.vision.isNotEmpty;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              BrandSpace.lg,
              BrandSpace.md,
              BrandSpace.lg,
              BrandTabBar.height,
            ),
            children: [
              _ProfileRow(profile: data.profile, config: config),
              const SizedBox(height: 10),
              _MoreRow(
                label: 'nuestros_servicios'.tr(),
                route: AppRoutes.services,
                visible: !tabs.contains(TabModule.services),
              ),
              _MoreRow(
                label: 'noticias'.tr(),
                route: AppRoutes.news,
                visible: !tabs.contains(TabModule.news),
              ),
              _MoreRow(
                label: 'preguntas_frecuentes'.tr(),
                route: AppRoutes.faq,
                visible: data.company.hasPreguntas,
              ),
              if (hasAbout)
                _MoreRow(
                  label: 'sobre_nosotros'.tr(),
                  onTap: () => _showAbout(data.company),
                ),
              const SizedBox(height: 18),
              SocialMediaLinks(
                empresa: data.company,
                userProfile: data.profile,
              ),
              const SizedBox(height: BrandSpace.sm),
              Text(
                'version_info'.tr(args: [data.version]),
                textAlign: TextAlign.center,
                style: tokens.body(12, color: tokens.textMuted),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<_MoreData> _load() async {
    final service = GetIt.I<CourierService>();
    final results = await Future.wait([
      service.getUserProfile(),
      service.getEmpresa(),
      PackageInfo.fromPlatform(),
    ]);
    return (
      profile: results[0] as UserProfile,
      company: results[1] as Empresa,
      version: (results[2] as PackageInfo).version,
    );
  }

  Future<void> _showAbout(Empresa company) async {
    await showBrandSheet<void>(
      context,
      scrollable: true,
      child: _AboutSheet(company: company),
    );
  }

}

/// Account identity, opening the membership card.
class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.profile, required this.config});

  final UserProfile profile;
  final BrandConfig config;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final name = profile.nombre.isEmpty ? config.name : profile.nombre;
    return BrandCard(
      onTap: () => context.push(AppRoutes.idCard),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tokens.accentWash(tokens.primary),
              shape: BoxShape.circle,
            ),
            child: Text(
              name.characters.first.toUpperCase(),
              style: tokens.head(16, color: tokens.primary),
            ),
          ),
          const SizedBox(width: BrandSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tokens.body(14, weight: FontWeight.w700),
                ),
                Text(
                  [profile.cuenta, profile.nombreSucursal]
                      .where((value) => value.isNotEmpty)
                      .join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tokens.body(11, color: tokens.textMuted),
                ),
              ],
            ),
          ),
          const BrandChevron(),
        ],
      ),
    );
  }
}

/// One navigation row of the more screen.
class _MoreRow extends StatelessWidget {
  const _MoreRow({
    required this.label,
    this.route,
    this.onTap,
    this.visible = true,
  });

  final String label;
  final String? route;
  final VoidCallback? onTap;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    if (!visible) {
      return const SizedBox.shrink();
    }
    return BrandCard(
      onTap: onTap ?? (route == null ? null : () => context.push(route!)),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: tokens.body(14, weight: FontWeight.w600),
            ),
          ),
          const BrandChevron(),
        ],
      ),
    );
  }
}

/// Mission and vision, as published by the backend.
class _AboutSheet extends StatelessWidget {
  const _AboutSheet({required this.company});

  final Empresa company;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return BrandSheet(
      title: 'sobre_nosotros'.tr(),
      maxHeightFactor: 0.8,
      children: [
        if (company.mision.isNotEmpty) ...[
          Text('mision'.tr(), style: tokens.head(15)),
          const SizedBox(height: 6),
          Text(
            company.mision,
            style: tokens.body(13, color: tokens.textMuted, height: 1.5),
          ),
          const SizedBox(height: BrandSpace.md),
        ],
        if (company.vision.isNotEmpty) ...[
          Text('vision'.tr(), style: tokens.head(15)),
          const SizedBox(height: 6),
          Text(
            company.vision,
            style: tokens.body(13, color: tokens.textMuted, height: 1.5),
          ),
        ],
      ],
    );
  }
}
