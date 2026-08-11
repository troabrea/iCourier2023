import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../domain/package_stage.dart';
import '../theme/brand_tokens.dart';
import 'brand_foundations.dart';
import 'core_components.dart';

/// What the home card should lead with.
enum HomeStatus {
  /// Packages are waiting at the branch: the customer can act now.
  ready,

  /// Nothing to collect yet, but something is on its way.
  onTheWay,

  /// No packages at all — the moment to invite a first order.
  empty,
}

/// The card that overlaps the brand header.
///
/// It leads with whatever matters most right now, so the same slot answers
/// three different questions instead of showing a zero.
class HomeStatusCard extends StatelessWidget {
  const HomeStatusCard({
    super.key,
    required this.status,
    this.count = 0,
    this.total = '',
    this.currency = '',
    this.branch = '',
    this.nextContent = '',
    this.nextStage,
    this.nextRetained = false,
    this.onTap,
    this.onPickup,
    this.onDelivery,
    this.onShowAddress,
  });

  final HomeStatus status;

  /// Packages in the state the card is reporting.
  final int count;
  final String total;
  final String currency;
  final String branch;

  /// The package closest to arriving, described for [HomeStatus.onTheWay].
  final String nextContent;
  final PackageStage? nextStage;
  final bool nextRetained;

  final VoidCallback? onTap;
  final VoidCallback? onPickup;
  final VoidCallback? onDelivery;
  final VoidCallback? onShowAddress;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
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
              child: switch (status) {
                HomeStatus.ready => _Ready(
                    count: count,
                    total: total,
                    currency: currency,
                    branch: branch,
                    onPickup: onPickup,
                    onDelivery: onDelivery,
                  ),
                HomeStatus.onTheWay => _OnTheWay(
                    count: count,
                    content: nextContent,
                    stage: nextStage ?? PackageStage.origen,
                    retained: nextRetained,
                  ),
                HomeStatus.empty => _Empty(onShowAddress: onShowAddress),
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Eyebrow with a status dot, shared by the two populated states.
class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: BrandSpace.xs),
        Expanded(
          child: Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tokens.eyebrow(11),
          ),
        ),
      ],
    );
  }
}

/// Big count plus a supporting line, shared by the two populated states.
class _Headline extends StatelessWidget {
  const _Headline({required this.count, required this.subtitle, this.glyph});

  final int count;
  final String subtitle;
  final String? glyph;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Row(
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
              if (subtitle.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tokens.body(
                    13,
                    weight: FontWeight.w500,
                    color: tokens.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (glyph != null) ...[
          const SizedBox(width: BrandSpace.sm),
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tokens.accentWash(tokens.primary),
              shape: BoxShape.circle,
            ),
            child: BrandGlyph(glyph!, color: tokens.primary, size: 24),
          ),
        ],
      ],
    );
  }
}

class _Ready extends StatelessWidget {
  const _Ready({
    required this.count,
    required this.total,
    required this.currency,
    required this.branch,
    this.onPickup,
    this.onDelivery,
  });

  final int count;
  final String total;
  final String currency;
  final String branch;
  final VoidCallback? onPickup;
  final VoidCallback? onDelivery;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Eyebrow(label: 'listos_para_ti'.tr(), color: tokens.success),
        const SizedBox(height: 10),
        _Headline(
          count: count,
          subtitle: [
            '$currency$total',
            if (branch.trim().isNotEmpty) branch,
          ].join(' · '),
          glyph: BrandIcons.available,
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
    );
  }
}

/// Nothing to collect yet, so the card shows how far the nearest package got.
class _OnTheWay extends StatelessWidget {
  const _OnTheWay({
    required this.count,
    required this.content,
    required this.stage,
    required this.retained,
  });

  final int count;
  final String content;
  final PackageStage stage;
  final bool retained;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Eyebrow(label: 'paquetes_en_camino'.tr(), color: tokens.primary),
        const SizedBox(height: 10),
        _Headline(
          count: count,
          subtitle: content.trim().isEmpty
              ? ''
              : '${'proximo_a_llegar'.tr()} · $content',
          glyph: BrandIcons.shipped,
        ),
        const SizedBox(height: BrandSpace.md),
        Divider(height: 1, color: tokens.border),
        const SizedBox(height: BrandSpace.md),
        // The journey of the nearest package, in the same four macro steps the
        // detail screen uses, so the progress reads the same everywhere.
        MacroStepper(stage: stage),
        if (retained) ...[
          const SizedBox(height: BrandSpace.sm),
          Row(
            children: [
              BrandGlyph(
                BrandIcons.missingInvoice,
                color: tokens.warning,
                size: 13,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'retenido_falta_factura'.tr(),
                  style: tokens.body(
                    11,
                    weight: FontWeight.w700,
                    color: tokens.warning,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// No packages at all: the address is what the customer needs to get one.
class _Empty extends StatelessWidget {
  const _Empty({this.onShowAddress});

  final VoidCallback? onShowAddress;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tokens.accentWash(tokens.primary),
                shape: BoxShape.circle,
              ),
              child: BrandGlyph(
                BrandIcons.receptions,
                color: tokens.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: BrandSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'sin_paquetes_titulo'.tr(),
                    style: tokens.head(18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'sin_paquetes_cuerpo'.tr(),
                    style: tokens.body(
                      13,
                      color: tokens.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (onShowAddress != null) ...[
          const SizedBox(height: BrandSpace.md),
          BrandPrimaryButton(
            label: 'ver_mi_direccion'.tr(),
            pill: true,
            fontSize: 13,
            verticalPadding: 11,
            onPressed: onShowAddress,
          ),
        ],
      ],
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
    if (widget.total == 0) {
      return const SizedBox.shrink();
    }
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
