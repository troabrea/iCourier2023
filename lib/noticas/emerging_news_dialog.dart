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
  ImageProvider<Object>? imageProvider,
}) async {
  final media = MediaQuery.of(context);
  final reduceMotion = media.disableAnimations || media.accessibleNavigation;
  final openNews = await Navigator.of(context, rootNavigator: true).push<bool>(
    PageRouteBuilder<bool>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: context.brand.modalScrim,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 420),
      reverseTransitionDuration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) =>
          EmergingNewsDialog(
        announcement: announcement,
        imageProvider: imageProvider,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final arrival = CurvedAnimation(
          parent: animation,
          curve: const Cubic(0.16, 1, 0.3, 1),
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          key: const ValueKey('emerging-news-roll-down'),
          position: Tween<Offset>(
            begin: const Offset(0, -0.1),
            end: Offset.zero,
          ).animate(arrival),
          child: FadeTransition(opacity: arrival, child: child),
        );
      },
    ),
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
    final title = news?.titulo.trim() ?? '';
    final preview = news?.previewText.trim() ?? '';
    final semanticLabel = title.isEmpty ? 'noticias'.tr() : title;

    return Dialog(
      backgroundColor: tokens.surface,
      insetPadding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusLg),
      ),
      child: SizedBox(
        key: const ValueKey('emerging-news-card'),
        width: viewport.width * 0.8,
        height: viewport.height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ColoredBox(
                color: tokens.surfaceAlt,
                child: Image(
                  image: imageProvider ??
                      CachedNetworkImageProvider(announcement.imageUrl),
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
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
    );
  }
}
