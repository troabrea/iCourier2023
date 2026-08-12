import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../theme/brand_tokens.dart';
import 'brand_foundations.dart';

/// Placeholder blocks shown while a screen loads. Never a full-screen spinner.
class BrandSkeleton extends StatelessWidget {
  const BrandSkeleton({super.key, this.rows = 4});

  final int rows;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return SafeArea(
      // A screen that shows this as its whole body has no app bar to keep the
      // placeholders clear of the status bar. Under one, this costs nothing:
      // the Scaffold has already taken the inset off the body.
      bottom: false,
      child: ListView.separated(
        padding: const EdgeInsets.all(BrandSpace.lg),
        // Sized to its content so it can also sit inside another scroll view.
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: rows,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) => Semantics(
          label: 'trabajando'.tr(),
          child: Container(
            height: index.isEven ? 92 : 64,
            decoration: BoxDecoration(
              color: tokens.surfaceAlt,
              borderRadius: BorderRadius.circular(tokens.radiusMd),
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty result for any list, optionally offering the action that fills it.
class BrandEmptyState extends StatelessWidget {
  const BrandEmptyState({
    super.key,
    required this.messageKey,
    this.glyph = BrandIcons.receptions,
    this.actionLabel,
    this.onAction,
  });

  final String messageKey;
  final String glyph;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BrandSpace.lg,
          vertical: 48,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandGlyph(glyph, color: tokens.border, size: 74),
            const SizedBox(height: BrandSpace.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 230),
              child: Text(
                messageKey.tr(),
                textAlign: TextAlign.center,
                style: tokens.body(13, color: tokens.textMuted, height: 1.45),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: BrandSpace.md),
              BrandOutlineButton(
                label: actionLabel!,
                expand: false,
                pill: true,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Recoverable failure with a single retry action.
class BrandErrorState extends StatelessWidget {
  const BrandErrorState({super.key, required this.onRetry, this.messageKey});

  final VoidCallback onRetry;
  final String? messageKey;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BrandSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 44, color: tokens.danger),
            const SizedBox(height: BrandSpace.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Text(
                (messageKey ?? 'error_reintentar').tr(),
                textAlign: TextAlign.center,
                style: tokens.body(13, color: tokens.textMuted, height: 1.45),
              ),
            ),
            const SizedBox(height: BrandSpace.md),
            BrandOutlineButton(
              label: 'recargar'.tr(),
              expand: false,
              pill: true,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline notice explaining why a package is blocked, with its remedy.
class BrandNotice extends StatelessWidget {
  const BrandNotice({
    super.key,
    required this.title,
    required this.message,
    required this.glyph,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String glyph;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return BrandCard(
      color: tokens.surfaceAlt,
      borderColor: tokens.warning,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: BrandGlyph(glyph, color: tokens.warning, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: tokens.body(13, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: tokens.body(12, color: tokens.textMuted, height: 1.4),
                ),
                if (actionLabel != null && onAction != null)
                  Padding(
                    padding: const EdgeInsets.only(top: BrandSpace.xs),
                    child: BrandPrimaryButton(
                      label: actionLabel!,
                      expand: false,
                      fontSize: 12,
                      verticalPadding: 8,
                      background: tokens.warning,
                      onPressed: onAction,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
