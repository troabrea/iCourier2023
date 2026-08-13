import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design_system/brand_foundations.dart';
import '../design_system/content_components.dart';
import '../design_system/core_components.dart';
import '../navigation/app_routes.dart';
import '../services/model/noticia.dart';
import '../theme/brand_tokens.dart';

/// Long-form reading template: title in the head font, muted date, body at
/// 15/1.6 over `surface` (spec §3.1).
class NoticiaDetallePage extends StatelessWidget {
  const NoticiaDetallePage({super.key, required this.noticia});

  final Noticia noticia;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final title = noticia.titulo.isEmpty ? 'noticias'.tr() : noticia.titulo;
    final summary = noticia.summaryText;
    final body = noticia.plainContent;
    final date = formatNewsDate(context, noticia);
    final externalUri = noticia.externalUri;

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: ScreenHeader(
        title: 'noticias'.tr(),
        onBack: context.popOrHome,
        trailing: externalUri == null
            ? null
            : IconButton(
                onPressed: () => _open(externalUri),
                icon: Icon(Icons.open_in_new, color: tokens.onPrimary),
                tooltip: 'ver_mas'.tr(),
              ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            BrandSpace.lg,
            BrandSpace.lg,
            BrandSpace.lg,
            BrandTabBar.height,
          ),
          children: [
            Hero(
              tag: newsHeroTag(noticia.heroIdentity),
              child: Material(
                type: MaterialType.transparency,
                child: Text(title, style: tokens.head(20)),
              ),
            ),
            if (date.isNotEmpty) ...[
              const SizedBox(height: BrandSpace.xxs),
              Text(date, style: tokens.body(13, color: tokens.textMuted)),
            ],
            const SizedBox(height: BrandSpace.md),
            if (summary.isNotEmpty) ...[
              Text(
                summary,
                style: tokens.body(15, weight: FontWeight.w600, height: 1.5),
              ),
              const SizedBox(height: BrandSpace.sm),
            ],
            if (body.isNotEmpty && body != summary)
              SelectableText(
                body,
                style: tokens.body(15, height: 1.6),
              ),
            if (externalUri != null) ...[
              const SizedBox(height: BrandSpace.lg),
              BrandOutlineButton(
                label: 'ver_mas'.tr(),
                pill: true,
                foreground: tokens.primary,
                onPressed: () => _open(externalUri),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _open(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
}
