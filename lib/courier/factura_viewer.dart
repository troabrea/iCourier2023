import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design_system/brand_foundations.dart';
import '../design_system/brand_states.dart';
import '../design_system/core_components.dart';
import '../theme/brand_tokens.dart';

/// Full-screen document viewer for an attached invoice.
///
/// Zoomable, with its own loading and error states and an action to open the
/// original document outside the app.
class FacturaViewerPage extends StatelessWidget {
  const FacturaViewerPage({
    super.key,
    required this.url,
    required this.title,
  });

  final String url;
  final String title;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: ScreenHeader(
        title: title,
        titleSize: 18,
        onBack: context.canPop() ? context.pop : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _copy(context),
              icon: Icon(Icons.link, color: tokens.onPrimary),
              tooltip: 'copiar'.tr(),
            ),
            IconButton(
              onPressed: _open,
              icon: Icon(Icons.open_in_new, color: tokens.onPrimary),
              tooltip: 'ver_mas'.tr(),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: InteractiveViewer(
          maxScale: 5,
          child: Center(
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              placeholder: (context, _) => const BrandSkeleton(rows: 1),
              errorWidget: (context, _, __) => Padding(
                padding: const EdgeInsets.all(BrandSpace.lg),
                child: BrandErrorState(onRetry: _open),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('copiar'.tr())),
    );
  }

  Future<void> _open() async {
    final uri = Uri.tryParse(url);
    if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
