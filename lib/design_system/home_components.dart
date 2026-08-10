import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../theme/brand_tokens.dart';
import 'brand_foundations.dart';

/// The card that overlaps the brand header and leads with what is ready.
///
/// It carries the two capability-gated actions, so a brand without delivery or
/// payments simply renders fewer buttons rather than a different screen.
class AvailabilityHeroCard extends StatelessWidget {
  const AvailabilityHeroCard({
    super.key,
    required this.count,
    required this.total,
    required this.currency,
    required this.branch,
    this.onTap,
    this.onPickup,
    this.onDelivery,
  });

  final int count;
  final String total;
  final String currency;
  final String branch;
  final VoidCallback? onTap;
  final VoidCallback? onPickup;
  final VoidCallback? onDelivery;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final summary = [
      '$currency$total',
      if (branch.trim().isNotEmpty) branch,
    ].join(' · ');

    return Transform.translate(
      offset: const Offset(0, -30),
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(tokens.radiusLg),
          boxShadow: BrandElevation.hero,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(tokens.radiusLg),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: tokens.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: BrandSpace.xs),
                      Text(
                        'listos_para_ti'.tr().toUpperCase(),
                        style: tokens.eyebrow(11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              TextSpan(
                                text: '$count',
                                style: tokens.head(34, height: 1),
                                children: [
                                  TextSpan(
                                    text: ' ${'paquetes'.tr()}',
                                    style: tokens.body(
                                      15,
                                      weight: FontWeight.w600,
                                      color: tokens.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              summary,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: tokens.body(
                                13,
                                weight: FontWeight.w500,
                                color: tokens.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: BrandSpace.sm),
                      Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: tokens.accentWash(tokens.primary),
                          shape: BoxShape.circle,
                        ),
                        child: BrandGlyph(
                          BrandIcons.available,
                          color: tokens.primary,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  if (onPickup != null || onDelivery != null) ...[
                    const SizedBox(height: BrandSpace.md),
                    Row(
                      children: [
                        if (onPickup != null)
                          Expanded(
                            child: BrandPrimaryButton(
                              label: 'notificar_retiro'.tr(),
                              pill: true,
                              fontSize: 13,
                              verticalPadding: 11,
                              onPressed: count == 0 ? null : onPickup,
                            ),
                          ),
                        if (onPickup != null && onDelivery != null)
                          const SizedBox(width: BrandSpace.xs),
                        if (onDelivery != null)
                          Expanded(
                            child: BrandOutlineButton(
                              label: 'domicilio'.tr(),
                              pill: true,
                              onPressed: count == 0 ? null : onDelivery,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Collapsible receptions summary grouped by macro state.
class ReceptionsGroupCard extends StatefulWidget {
  const ReceptionsGroupCard({
    super.key,
    required this.total,
    required this.children,
    this.initiallyExpanded = false,
  });

  final int total;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  State<ReceptionsGroupCard> createState() => _ReceptionsGroupCardState();
}

class _ReceptionsGroupCardState extends State<ReceptionsGroupCard> {
  late bool _open = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return BrandCard(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: _open,
            child: InkWell(
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BrandSpace.md,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    BrandGlyph(
                      BrandIcons.receptions,
                      color: tokens.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'recepciones'.tr(),
                        style: tokens.body(15, weight: FontWeight.w600),
                      ),
                    ),
                    BrandPill(
                      label: '${widget.total}',
                      background: tokens.surfaceAlt,
                      foreground: tokens.text,
                    ),
                    const SizedBox(width: BrandSpace.xs),
                    Icon(
                      _open ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: tokens.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BrandSpace.md,
                0,
                BrandSpace.md,
                14,
              ),
              child: Column(children: widget.children),
            ),
        ],
      ),
    );
  }
}

/// Loyalty balance block, rendered only when the brand enables points.
class PointsCard extends StatelessWidget {
  const PointsCard({
    super.key,
    required this.label,
    required this.balance,
    this.onRedeem,
  });

  final String label;
  final String balance;
  final VoidCallback? onRedeem;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-1, -0.4),
          end: const Alignment(1, 0.4),
          colors: [
            Color.lerp(tokens.surface, tokens.secondary, 0.22)!,
            tokens.surface,
          ],
        ),
        border: Border.all(color: tokens.border),
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      padding: const EdgeInsets.all(BrandSpace.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: tokens.body(11, color: tokens.textMuted)),
                const SizedBox(height: 3),
                Text.rich(
                  TextSpan(
                    text: balance,
                    style: tokens.head(22),
                    children: [
                      TextSpan(
                        text: ' ${'pts'.tr()}',
                        style: tokens.body(
                          12,
                          weight: FontWeight.w600,
                          color: tokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onRedeem != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: GestureDetector(
                      onTap: onRedeem,
                      child: Text(
                        'canjear'.tr(),
                        style: tokens.body(
                          11,
                          weight: FontWeight.w600,
                          color: tokens.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tokens.secondary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.star_outline,
              size: 19,
              color: tokens.onSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Removable chip showing the filter applied to a list.
class BrandFilterChip extends StatelessWidget {
  const BrandFilterChip({
    super.key,
    required this.label,
    required this.onClear,
  });

  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(BrandShape.pill),
        child: InkWell(
          onTap: onClear,
          borderRadius: BorderRadius.circular(BrandShape.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: tokens.body(12, weight: FontWeight.w700)),
                const SizedBox(width: 6),
                Icon(Icons.close, size: 14, color: tokens.text),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
