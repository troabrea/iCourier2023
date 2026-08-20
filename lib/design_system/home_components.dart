import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../domain/package_stage.dart';
import '../theme/brand_tokens.dart';
import 'brand_foundations.dart';

/// One macro state on the home card: how many packages sit in it, a glance at
/// what they are, and the actions that state allows.
class HomeStageGroup {
  const HomeStageGroup({
    required this.stage,
    required this.count,
    required this.contents,
    required this.onOpen,
    this.retained,
    this.onPickup,
    this.onDelivery,
    this.onPay,
  });

  final PackageStage stage;
  final int count;

  /// What is inside, gathered from the packages themselves.
  final String contents;

  /// Opens the reception list already filtered by this state.
  final VoidCallback onOpen;

  /// The packages inside this state that the operation is holding, when there
  /// are any. Shown as a child of the state rather than a state of its own:
  /// being held is a condition on top of where the package is, not a place.
  final HomeRetainedGroup? retained;

  /// Only a state the customer can act on carries these.
  final VoidCallback? onPickup;
  final VoidCallback? onDelivery;
  final VoidCallback? onPay;
}

/// Packages held inside a state, waiting on the customer for an invoice.
class HomeRetainedGroup {
  const HomeRetainedGroup({
    required this.count,
    required this.contents,
    required this.onOpen,
  });

  final int count;
  final String contents;

  /// Opens the held packages, where each one leads to its post-alert.
  final VoidCallback onOpen;
}

/// The card that overlaps the brand header.
///
/// It leads with the count, then breaks it down by state so the customer sees
/// where every package stands without leaving home. With nothing to report it
/// invites a first order instead of showing a zero.
class HomeStatusCard extends StatelessWidget {
  const HomeStatusCard({
    super.key,
    this.total = 0,
    this.groups = const [],
    this.onOpenAll,
    this.onShowAddress,
    this.onRefresh,
    this.refreshing = false,
    this.banner,
  });

  /// Packages the customer still has something to wait for.
  final int total;
  final List<HomeStageGroup> groups;

  /// Opens the complete receptions list without a stage filter.
  final VoidCallback? onOpenAll;
  final VoidCallback? onShowAddress;

  /// Reloads the dashboard. Offered here as a button because the pull gesture
  /// is invisible and, once the redesign fits the home on one screen, easy to
  /// miss entirely.
  final VoidCallback? onRefresh;

  /// Swaps the control for a spinner, so a reload that lands on identical data
  /// still tells the customer the tap registered.
  final bool refreshing;

  /// Rides at the top of the card, full width and flush to the edge.
  ///
  /// The brand needs this seen, and inside the card it cannot be pushed off the
  /// fold by anything below: it travels with the one surface that is always
  /// first on the screen, packages or not.
  final Widget? banner;

  /// Height this card will take, so the page can budget what surrounds it.
  ///
  /// Assumes the two-line digest on every state: erring tall only folds the
  /// quick actions away, while erring short would push the banner off screen.
  static double heightFor({
    required int stageCount,
    required bool withActions,
    double bannerHeight = 0,
  }) {
    const padding = 18 * 2;
    const headline = 52 + BrandSpace.md;
    const tile = 1 + 12 * 2 + 40;
    // Three pills do not fit one line on a phone, so they wrap. Budgeting for
    // a single row would under-reserve and push the banner off the fold.
    const actionsRow = 44 * 2 + BrandSpace.xs + 12;
    return bannerHeight +
        padding +
        headline +
        stageCount * tile +
        (withActions ? actionsRow : 0.0) -
        // The card is pulled up onto the header skirt.
        30;
  }

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
        // Clipped by the card so the banner can sit flush against the top edge
        // and still take its rounded corners.
        child: ClipRRect(
          borderRadius: BorderRadius.circular(tokens.radiusLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (banner != null) banner!,
              Padding(
                padding: const EdgeInsets.all(18),
                child: total == 0
                    ? _Empty(
                        onShowAddress: onShowAddress,
                        onRefresh: onRefresh,
                        refreshing: refreshing,
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Headline(
                            count: total,
                            glyph: BrandIcons.receptions,
                            onOpenAll: onOpenAll,
                            onRefresh: onRefresh,
                            refreshing: refreshing,
                          ),
                          const SizedBox(height: BrandSpace.md),
                          for (final group in groups)
                            _StageTile(group: group),
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

/// Big count plus the package mark.
class _Headline extends StatelessWidget {
  const _Headline({
    required this.count,
    this.glyph,
    this.onOpenAll,
    this.onRefresh,
    this.refreshing = false,
  });

  final int count;
  final String? glyph;
  final VoidCallback? onOpenAll;
  final VoidCallback? onRefresh;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final packageLabel = 'paquetes_contados'.plural(count);
    final countText = Text.rich(
      TextSpan(
        text: '$count',
        style: tokens.head(34, height: 1),
        children: [
          TextSpan(
            text: ' $packageLabel',
            style: tokens.body(
              15,
              weight: FontWeight.w600,
              color: tokens.textMuted,
            ),
          ),
        ],
      ),
    );
    final countSummary = onOpenAll == null
        ? countText
        : Semantics(
            button: true,
            label: '$count $packageLabel, ${'recepciones'.tr()}',
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onOpenAll,
                borderRadius: BorderRadius.circular(tokens.radiusSm),
                child: SizedBox(
                  height: 52,
                  child: Row(
                    children: [
                      Flexible(child: countText),
                      const SizedBox(width: BrandSpace.xxs),
                      BrandChevron(
                        size: 18,
                        color: tokens.accessibleForeground(
                          tokens.surface,
                          preferred: tokens.primary,
                          minimumContrast: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: countSummary),
        if (onRefresh != null)
          _RefreshAction(onTap: onRefresh!, busy: refreshing),
        if (glyph != null) ...[
          const SizedBox(width: BrandSpace.xxs),
          BrandGlyphTile(
            asset: glyph!,
            size: 52,
            glyphSize: 24,
            shape: BoxShape.circle,
          ),
        ],
      ],
    );
  }
}

/// Held packages, hung under the state they belong to.
///
/// Indented and smaller than its parent so it reads as a condition of that
/// state rather than another step of the journey, and in the warning colour
/// because it is the one row waiting on the customer.
class _RetainedSubTile extends StatelessWidget {
  const _RetainedSubTile({required this.group});

  final HomeRetainedGroup group;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final warningColors = tokens.softAccentPair(
      tokens.warning,
      opacity: 0.16,
      minimumContrast: 4.5,
    );
    return Semantics(
      button: true,
      child: InkWell(
        onTap: group.onOpen,
        child: Padding(
          // Cleared past the parent mark so the indent is unmistakable.
          padding: const EdgeInsets.only(
            left: 38 + BrandSpace.sm,
            bottom: 12,
          ),
          child: Row(
            children: [
              BrandGlyphTile(
                asset: BrandIcons.missingInvoice,
                accent: tokens.warning,
                size: 30,
                glyphSize: 16,
              ),
              const SizedBox(width: BrandSpace.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'retenido'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tokens.body(
                        13,
                        weight: FontWeight.w700,
                        color: tokens.warning,
                      ),
                    ),
                    if (group.contents.trim().isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        group.contents,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tokens.body(11, color: tokens.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: BrandSpace.xs),
              BrandPill(
                label: '${group.count}',
                background: warningColors.background,
                foreground: warningColors.foreground,
                fontSize: 11,
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 2,
                ),
              ),
              const SizedBox(width: BrandSpace.xxs),
              BrandChevron(size: 14, color: tokens.warning),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reload control that lives inside the card.
class _RefreshAction extends StatelessWidget {
  const _RefreshAction({required this.onTap, this.busy = false});

  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final foreground = tokens.accessibleForeground(
      tokens.surface,
      preferred: tokens.primary,
      minimumContrast: 3,
    );
    return Semantics(
      button: true,
      label: 'refrescar'.tr(),
      child: GestureDetector(
        onTap: busy ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: busy
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: tokens.primary,
                    ),
                  )
                // In the brand colour: muted grey on a white card reads as a
                // control that is switched off.
                : Icon(Icons.refresh, size: 24, color: foreground),
          ),
        ),
      ),
    );
  }
}

/// One state of the journey, with what it holds and what can be done about it.
class _StageTile extends StatelessWidget {
  const _StageTile({required this.group});

  final HomeStageGroup group;

  static const _glyphs = <PackageStage, String>{
    PackageStage.origen: BrandIcons.received,
    PackageStage.ruta: BrandIcons.shipped,
    PackageStage.destino: BrandIcons.atDestination,
    PackageStage.disponible: BrandIcons.available,
    PackageStage.entregado: BrandIcons.receptions,
  };

  static const _labels = <PackageStage, String>{
    PackageStage.origen: 'recibido',
    PackageStage.ruta: 'en_ruta',
    PackageStage.destino: 'en_destino',
    PackageStage.disponible: 'disponibles',
    PackageStage.entregado: 'entregado',
  };

  bool get _actionable =>
      group.onPickup != null || group.onDelivery != null || group.onPay != null;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    // The state the customer can act on leads in the brand colour; the rest
    // read as progress, not as prompts.
    final accent =
        group.stage == PackageStage.disponible ? tokens.primary : tokens.text;
    final countColors = tokens.softAccentPair(
      accent,
      opacity: 0.14,
      minimumContrast: 4.5,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Leads the tile rather than closing it, so the last state does not
        // leave a rule hanging against the edge of the card.
        Divider(height: 1, color: tokens.border),
        Semantics(
          button: true,
          child: InkWell(
            onTap: group.onOpen,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  BrandGlyphTile(
                    asset: _glyphs[group.stage] ?? BrandIcons.receptions,
                    accent: accent == tokens.text ? tokens.textMuted : accent,
                  ),
                  const SizedBox(width: BrandSpace.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          (_labels[group.stage] ?? '').tr(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tokens.body(
                            14,
                            weight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                        if (group.contents.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            group.contents,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: tokens.body(12, color: tokens.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: BrandSpace.xs),
                  // The count rides beside the disclosure so the eye picks up
                  // every quantity in one vertical sweep.
                  BrandPill(
                    label: '${group.count}',
                    background: countColors.background,
                    foreground: countColors.foreground,
                    fontSize: 12,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                  ),
                  const SizedBox(width: BrandSpace.xxs),
                  const BrandChevron(),
                ],
              ),
            ),
          ),
        ),
        if (group.retained != null) _RetainedSubTile(group: group.retained!),
        if (_actionable) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: BrandSpace.xs,
              runSpacing: BrandSpace.xs,
              children: [
                if (group.onPickup != null)
                  BrandPrimaryButton(
                    label: 'notificar_retiro'.tr(),
                    expand: false,
                    pill: true,
                    fontSize: 12,
                    verticalPadding: 9,
                    onPressed: group.onPickup,
                  ),
                if (group.onPay != null)
                  BrandOutlineButton(
                    label: 'pago_en_linea'.tr(),
                    expand: false,
                    pill: true,
                    fontSize: 12,
                    verticalPadding: 9,
                    onPressed: group.onPay,
                  ),
                if (group.onDelivery != null)
                  BrandOutlineButton(
                    label: 'domicilio'.tr(),
                    expand: false,
                    pill: true,
                    fontSize: 12,
                    verticalPadding: 9,
                    onPressed: group.onDelivery,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Nothing pending: the moment to invite a first order instead of a zero.
class _Empty extends StatelessWidget {
  const _Empty({this.onShowAddress, this.onRefresh, this.refreshing = false});

  final VoidCallback? onShowAddress;
  final VoidCallback? onRefresh;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const BrandGlyphTile(
              asset: BrandIcons.receptions,
              size: 52,
              glyphSize: 26,
              shape: BoxShape.circle,
            ),
            const SizedBox(width: BrandSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('sin_paquetes_titulo'.tr(), style: tokens.head(18)),
                  const SizedBox(height: 4),
                  Text(
                    'sin_paquetes_cuerpo'.tr(),
                    style: tokens.body(13, color: tokens.textMuted, height: 1.4),
                  ),
                ],
              ),
            ),
            if (onRefresh != null)
              _RefreshAction(onTap: onRefresh!, busy: refreshing),
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
                    const BrandGlyphTile(
                      asset: BrandIcons.receptions,
                      size: 34,
                      glyphSize: 19,
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
    final redeemBackground = Color.lerp(
      tokens.surface,
      tokens.secondary,
      0.22,
    )!;
    final redeemForeground = tokens.accessibleForeground(
      redeemBackground,
      preferred: tokens.primary,
    );
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
                    padding: const EdgeInsets.only(top: 2),
                    child: TextButton(
                      onPressed: onRedeem,
                      style: TextButton.styleFrom(
                        foregroundColor: redeemForeground,
                        minimumSize: const Size(44, 44),
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                        tapTargetSize: MaterialTapTargetSize.padded,
                        textStyle: tokens.body(
                          12,
                          weight: FontWeight.w700,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('canjear'.tr()),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, size: 14),
                        ],
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
