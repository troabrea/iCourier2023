import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../design_system/brand_foundations.dart';
import '../theme/brand_tokens.dart';
import 'emerging_news_coordinator.dart';

typedef EmergingNewsImagePreloader = Future<Size?> Function(
  BuildContext context,
  String imageUrl,
);

/// Warms the campaign artwork so the popup never opens onto a loading flash.
Future<Size?> preloadEmergingNewsImage(
  BuildContext context,
  String imageUrl,
) async {
  final provider = CachedNetworkImageProvider(imageUrl);
  try {
    await precacheImage(provider, context);
    if (!context.mounted) {
      return null;
    }
    final completer = Completer<Size>();
    final stream = provider.resolve(createLocalImageConfiguration(context));
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, synchronousCall) {
        stream.removeListener(listener);
        if (!completer.isCompleted) {
          completer.complete(
            Size(
              info.image.width.toDouble(),
              info.image.height.toDouble(),
            ),
          );
        }
        info.dispose();
      },
      onError: (Object error, StackTrace? stackTrace) {
        stream.removeListener(listener);
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      },
    );
    stream.addListener(listener);
    return await completer.future;
  } on Exception {
    return null;
  }
}

/// Shows a centered campaign popup and reports whether its detail was requested.
Future<bool> showEmergingNewsDialog(
  BuildContext context, {
  required EmergingNewsAnnouncement announcement,
  ImageProvider<Object>? imageProvider,
  double imageAspectRatio = 0.5,
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
        imageAspectRatio: imageAspectRatio,
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
    this.imageAspectRatio = 0.5,
  });

  final EmergingNewsAnnouncement announcement;
  final ImageProvider<Object>? imageProvider;

  /// Width divided by height for the campaign artwork.
  final double imageAspectRatio;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final news = announcement.news;
    final viewport = MediaQuery.sizeOf(context);
    final title = news?.titulo.trim() ?? '';
    final preview = news?.previewText.trim() ?? '';
    final semanticLabel = title.isEmpty ? 'noticias'.tr() : title;
    final artworkSize = _fitArtwork(
      maximum: Size(viewport.width * 0.8, viewport.height * 0.6),
      aspectRatio: imageAspectRatio,
    );
    final footerNote =
        news == null ? 'noticia_emergente_cerrar_ayuda'.tr() : null;

    return Dialog(
      backgroundColor: tokens.surface,
      insetPadding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusLg),
      ),
      child: ConstrainedBox(
        key: const ValueKey('emerging-news-card'),
        constraints: BoxConstraints(
          minWidth: artworkSize.width,
          maxWidth: artworkSize.width,
          maxHeight: viewport.height - MediaQuery.paddingOf(context).vertical,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: artworkSize.width,
              height: artworkSize.height,
              child: Image(
                image: imageProvider ??
                    CachedNetworkImageProvider(announcement.imageUrl),
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
            Flexible(
              child: SingleChildScrollView(
                child: _AnnouncementFooter(
                  hasNews: news != null,
                  title: title,
                  preview: preview,
                  note: footerNote,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementFooter extends StatelessWidget {
  const _AnnouncementFooter({
    required this.hasNews,
    required this.title,
    required this.preview,
    required this.note,
  });

  final bool hasNews;
  final String title;
  final String preview;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(top: BorderSide(color: tokens.border)),
      ),
      padding: EdgeInsets.fromLTRB(
        BrandSpace.lg,
        hasNews ? BrandSpace.md : BrandSpace.sm,
        BrandSpace.lg,
        hasNews ? BrandSpace.lg : BrandSpace.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasNews && title.isNotEmpty)
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: tokens.head(18, height: 1.3),
            ),
          if (hasNews && title.isNotEmpty && preview.isNotEmpty)
            const SizedBox(height: BrandSpace.xs),
          if (hasNews && preview.isNotEmpty)
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
          if (hasNews) ...[
            const SizedBox(height: BrandSpace.md),
            BrandPrimaryButton(
              label: 'ver_mas'.tr(),
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: BrandSpace.sm),
          ],
          if (note != null)
            Text(
              note!,
              key: const ValueKey('emerging-news-footer-note'),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: tokens.body(
                12,
                height: 1.35,
                color: tokens.readableMuted(tokens.surface),
              ),
            ),
        ],
      ),
    );
  }
}

Size _fitArtwork({required Size maximum, required double aspectRatio}) {
  final safeAspectRatio =
      aspectRatio.isFinite && aspectRatio > 0 ? aspectRatio : 0.5;
  var width = maximum.width;
  var height = width / safeAspectRatio;
  if (height > maximum.height) {
    height = maximum.height;
    width = height * safeAspectRatio;
  }
  return Size(width, height);
}
