import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../design_system/brand_foundations.dart';
import '../theme/brand_tokens.dart';
import 'emerging_news_coordinator.dart';

typedef EmergingNewsImagePreloader = Future<bool> Function(
  BuildContext context,
  String imageUrl,
);

/// Warms the campaign artwork so the popup never opens onto a loading flash.
Future<bool> preloadEmergingNewsImage(
  BuildContext context,
  String imageUrl,
) async {
  try {
    await precacheImage(CachedNetworkImageProvider(imageUrl), context);
    return true;
  } on Exception {
    return false;
  }
}

/// Shows a centered campaign popup and reports whether its detail was requested.
Future<bool> showEmergingNewsDialog(
  BuildContext context, {
  required EmergingNewsAnnouncement announcement,
}) async {
  final openNews = await showDialog<bool>(
    context: context,
    barrierColor: context.brand.modalScrim,
    barrierDismissible: true,
    builder: (context) => EmergingNewsDialog(announcement: announcement),
  );
  return openNews ?? false;
}

/// Branded, one-time artwork with optional context from a matching news item.
class EmergingNewsDialog extends StatelessWidget {
  const EmergingNewsDialog({
    super.key,
    required this.announcement,
    this.imageProvider,
  });

  final EmergingNewsAnnouncement announcement;
  final ImageProvider<Object>? imageProvider;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final news = announcement.news;
    final viewport = MediaQuery.sizeOf(context);
    final maxImageHeight = math.min(
      viewport.width - (BrandSpace.lg * 4),
      viewport.height * (news == null ? 0.68 : 0.46),
    );
    final title = news?.titulo.trim() ?? '';
    final preview = news?.previewText.trim() ?? '';
    final semanticLabel = title.isEmpty ? 'noticias'.tr() : title;

    return Dialog(
      backgroundColor: tokens.surface,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: BrandSpace.lg,
        vertical: BrandSpace.xl,
      ),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusLg),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: viewport.height - (BrandSpace.xl * 2),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  ColoredBox(
                    color: tokens.surfaceAlt,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxImageHeight),
                      child: Image(
                        image: imageProvider ??
                            CachedNetworkImageProvider(announcement.imageUrl),
                        width: double.infinity,
                        fit: BoxFit.contain,
                        semanticLabel: semanticLabel,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: BrandGlyph(
                            BrandIcons.news,
                            size: 44,
                            color: tokens.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    top: BrandSpace.xs,
                    end: BrandSpace.xs,
                    child: Semantics(
                      button: true,
                      label: 'cerrar'.tr(),
                      child: Material(
                        color: tokens.surface,
                        shape: const CircleBorder(),
                        elevation: 0,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => Navigator.of(context).pop(false),
                          child: SizedBox.square(
                            dimension: 44,
                            child: Icon(
                              Icons.close,
                              size: 20,
                              color: tokens.text,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (news != null)
                Container(
                  decoration: BoxDecoration(
                    color: tokens.surface,
                    border: Border(top: BorderSide(color: tokens.border)),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    BrandSpace.lg,
                    BrandSpace.md,
                    BrandSpace.lg,
                    BrandSpace.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (title.isNotEmpty)
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: tokens.head(18, height: 1.3),
                        ),
                      if (title.isNotEmpty && preview.isNotEmpty)
                        const SizedBox(height: BrandSpace.xs),
                      if (preview.isNotEmpty)
                        Text(
                          preview,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: tokens.body(
                            13,
                            height: 1.45,
                            color: tokens.readableMuted(tokens.surface),
                          ),
                        ),
                      const SizedBox(height: BrandSpace.md),
                      BrandPrimaryButton(
                        label: 'ver_mas'.tr(),
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
