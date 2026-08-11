import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../domain/package_stage.dart';
import '../services/model/recepcion.dart';
import '../theme/brand_config.dart';
import '../theme/brand_tokens.dart';
import 'brand_foundations.dart';

/// Resolves the accent that represents a package across every surface.
Color packageAccent(BrandTokens tokens, PackageStage stage, bool retained) {
  if (stage == PackageStage.entregado) {
    return tokens.success;
  }
  return retained ? tokens.warning : tokens.primary;
}

/// Brand header shown on the home tab.
///
/// The gradient runs from `primary` to the derived `headerGradientEnd`, with
/// two translucent discs bleeding past the edges and a rounded skirt that the
/// first content card overlaps.
class BrandHeader extends StatelessWidget {
  const BrandHeader({
    super.key,
    required this.greeting,
    required this.account,
    required this.capabilities,
    this.accountName,
    this.points,
    this.unread = 0,
    this.onMessages,
    this.onAccounts,
    this.onCarnet,
    this.onRefresh,
    this.onContact,
    this.contactIcon = Icons.chat_bubble_outline,
  });

  /// First name of the signed-in customer.
  final String greeting;

  /// Account code shown inside the switcher chip.
  final String account;
  final BrandCapabilities capabilities;
  final String? accountName;
  final num? points;
  final int unread;
  final VoidCallback? onMessages;
  final VoidCallback? onAccounts;
  final VoidCallback? onCarnet;
  final VoidCallback? onRefresh;

  /// Opens the branch WhatsApp or the brand chat, when either is configured.
  final VoidCallback? onContact;

  /// Mark of the resolved channel, so the button shows what it will open.
  final IconData contactIcon;

  String get _initial {
    final source = (accountName?.trim().isNotEmpty ?? false)
        ? accountName!.trim()
        : greeting.trim();
    return source.isEmpty ? '' : source.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(BrandShape.headerSkirt),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: const Alignment(-0.75, -1),
            end: const Alignment(0.75, 1),
            colors: [tokens.primary, tokens.headerGradientEnd],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -70,
              right: -50,
              child: _Disc(size: 200, color: tokens.headerOverlay(0.12)),
            ),
            Positioned(
              bottom: -90,
              left: -40,
              child: _Disc(size: 190, color: tokens.headerOverlay(0.08)),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  BrandSpace.lg,
                  BrandSpace.md,
                  BrandSpace.lg,
                  44,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _identity(tokens)),
                    const SizedBox(width: BrandSpace.xs),
                    _actions(tokens),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _identity(BrandTokens tokens) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Avatar(
            initial: _initial,
            onTap: onAccounts,
            tokens: tokens,
          ),
          const SizedBox(width: 11),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'saludo_hola'.tr(),
                  style: tokens.body(
                    12,
                    color: tokens.onPrimary.withValues(alpha: 0.85),
                  ),
                ),
                Text(
                  greeting,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tokens.head(18, color: tokens.onPrimary, height: 1.15),
                ),
                if (account.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  _AccountChip(
                    code: account,
                    onTap: onAccounts,
                    tokens: tokens,
                  ),
                ],
                if (capabilities.points && points != null) ...[
                  const SizedBox(height: BrandSpace.xs),
                  Text(
                    '$points',
                    style: tokens.head(22, color: tokens.onPrimary),
                  ),
                ],
              ],
            ),
          ),
        ],
      );

  Widget _actions(BrandTokens tokens) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onRefresh != null)
            _HeaderButton(
              icon: Icons.refresh,
              onTap: onRefresh,
              tokens: tokens,
              semanticLabel: 'refrescar'.tr(),
            ),
          if (onContact != null) ...[
            const SizedBox(width: 6),
            _HeaderButton(
              icon: contactIcon,
              onTap: onContact,
              tokens: tokens,
              semanticLabel: 'escribenos'.tr(),
            ),
          ],
          if (onCarnet != null) ...[
            const SizedBox(width: 6),
            _HeaderButton(
              icon: Icons.badge_outlined,
              onTap: onCarnet,
              tokens: tokens,
              semanticLabel: 'carnet_membresia'.tr(),
            ),
          ],
          if (onMessages != null) ...[
            const SizedBox(width: 6),
            _HeaderButton(
              icon: Icons.notifications_none,
              onTap: onMessages,
              tokens: tokens,
              badge: unread,
              semanticLabel: 'sus_mensajes'.tr(),
            ),
          ],
        ],
      );
}

class _Disc extends StatelessWidget {
  const _Disc({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initial, required this.tokens, this.onTap});

  final String initial;
  final BrandTokens tokens;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: onTap != null,
        label: 'sus_cuentas'.tr(),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tokens.headerOverlay(0.22),
              shape: BoxShape.circle,
              border: Border.all(color: tokens.headerOverlay(0.45), width: 1.5),
            ),
            child: Text(
              initial,
              style: tokens.head(15, color: tokens.onPrimary),
            ),
          ),
        ),
      );
}

class _AccountChip extends StatelessWidget {
  const _AccountChip({required this.code, required this.tokens, this.onTap});

  final String code;
  final BrandTokens tokens;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: tokens.headerOverlay(0.2),
            borderRadius: BorderRadius.circular(BrandShape.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tokens.body(
                    10,
                    weight: FontWeight.w600,
                    color: tokens.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down,
                size: 12,
                color: tokens.onPrimary,
              ),
            ],
          ),
        ),
      );
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.tokens,
    required this.semanticLabel,
    this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final BrandTokens tokens;
  final String semanticLabel;
  final VoidCallback? onTap;
  final int badge;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: semanticLabel,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tokens.headerOverlay(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 18, color: tokens.onPrimary),
                  ),
                  if (badge > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 15),
                        height: 15,
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: tokens.danger,
                          borderRadius:
                              BorderRadius.circular(BrandShape.pill),
                        ),
                        child: Text(
                          '$badge',
                          style: tokens.body(
                            9,
                            weight: FontWeight.w700,
                            color: tokens.onAccent(tokens.danger),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
}

/// Header for tab roots and stacked screens.
///
/// Renders as a solid `primary` band rather than a Material app bar so the
/// title typography and the status-bar inset match the design reference.
class ScreenHeader extends StatefulWidget implements PreferredSizeWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
    this.titleSize = 20,
    this.onSearchChanged,
    this.searchHint,
  });

  /// Root headers of a tab use the larger 24pt title.
  const ScreenHeader.tab({
    super.key,
    required this.title,
    this.trailing,
    this.onSearchChanged,
    this.searchHint,
  })  : onBack = null,
        titleSize = 24;

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final double titleSize;

  /// Supplying this adds a search action that replaces the title with an
  /// inline field, so filtering never costs the customer a row of screen.
  final ValueChanged<String>? onSearchChanged;
  final String? searchHint;

  /// Height of the band below the status bar.
  ///
  /// Any action forces a row as tall as a Material icon button (48, above the
  /// 44pt minimum target); a plain tab title only needs its own line box.
  static const double _actionRowHeight = 48;

  @override
  Size get preferredSize => Size.fromHeight(
        BrandSpace.sm +
            (onBack != null || trailing != null || onSearchChanged != null
                ? _actionRowHeight
                : titleSize * 1.5) +
            BrandSpace.md,
      );

  @override
  State<ScreenHeader> createState() => _ScreenHeaderState();
}

class _ScreenHeaderState extends State<ScreenHeader> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  bool _searching = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _searching = true);
    _searchFocus.requestFocus();
  }

  void _closeSearch() {
    _searchController.clear();
    widget.onSearchChanged?.call('');
    _searchFocus.unfocus();
    setState(() => _searching = false);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final onBack = widget.onBack;
    final trailing = widget.trailing;
    return Material(
      color: tokens.primary,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BrandSpace.lg,
                BrandSpace.sm,
                BrandSpace.lg,
                BrandSpace.md,
              ),
              child: Row(
                children: [
                  if (onBack != null) ...[
                    Semantics(
                      button: true,
                      label: 'atras'.tr(),
                      child: GestureDetector(
                        onTap: onBack,
                        behavior: HitTestBehavior.opaque,
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            size: 20,
                            color: tokens.onPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: BrandSpace.xxs),
                  ],
                  Expanded(
                    child: _searching
                        ? _SearchField(
                            controller: _searchController,
                            focusNode: _searchFocus,
                            hint: widget.searchHint ?? 'buscar'.tr(),
                            onChanged: widget.onSearchChanged!,
                          )
                        : Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tokens.head(
                              widget.titleSize,
                              color: tokens.onPrimary,
                            ),
                          ),
                  ),
                  if (widget.onSearchChanged != null)
                    IconButton(
                      onPressed: _searching ? _closeSearch : _openSearch,
                      icon: Icon(
                        _searching ? Icons.close : Icons.search,
                        color: tokens.onPrimary,
                      ),
                      tooltip: 'buscar'.tr(),
                    ),
                  if (trailing != null && !_searching) trailing,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline search field that takes over the header title.
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      cursorColor: tokens.onPrimary,
      style: tokens.body(
        16,
        weight: FontWeight.w600,
        color: tokens.onPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: tokens.body(
          16,
          color: tokens.onPrimary.withValues(alpha: 0.6),
        ),
        filled: false,
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
    );
  }
}

/// Floating navigation dock.
///
/// The design reference raises the home button above the bar; here it sits
/// inside the container instead, so the dock reads as one solid piece and
/// nothing overlaps the content scrolling underneath.
class BrandTabBar extends StatelessWidget {
  const BrandTabBar({
    super.key,
    required this.modules,
    required this.index,
    required this.onTap,
  });

  final List<TabModule> modules;
  final int index;
  final ValueChanged<int> onTap;

  /// Height of the row that holds every destination.
  static const double _rowHeight = 52;

  /// Bottom inset a scrolling screen must reserve so its last row clears the
  /// floating dock, including the home indicator area.
  static const double height = 108;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final homeIndex = modules.indexOf(TabModule.home);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(BrandSpace.sm, 0, BrandSpace.sm, 22),
        child: Container(
          decoration: BoxDecoration(
            color: tokens.surface,
            border: Border.all(color: tokens.border),
            borderRadius: BorderRadius.circular(BrandShape.tabDock),
            boxShadow: BrandElevation.dock,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: BrandSpace.xs,
            vertical: 6,
          ),
          child: SizedBox(
            height: _rowHeight,
            child: Row(
              children: [
                for (var slot = 0; slot < modules.length; slot++)
                  Expanded(
                    child: slot == homeIndex
                        ? Center(
                            child: _HomeButton(
                              selected: slot == index,
                              onTap: () => onTap(slot),
                            ),
                          )
                        : _TabButton(
                            module: modules[slot],
                            selected: slot == index,
                            onTap: () => onTap(slot),
                          ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.module,
    required this.selected,
    required this.onTap,
  });

  final TabModule module;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final color = selected ? tokens.primary : tokens.textMuted;
    return Semantics(
      button: true,
      selected: selected,
      label: _tabLabel(module),
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: SizedBox(
          height: BrandTabBar._rowHeight,
          child: Center(
            child: module == TabModule.more
                ? BrandMoreGlyph(color: color)
                : BrandGlyph(_tabGlyph(module), color: color, size: 29),
          ),
        ),
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  const _HomeButton({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Semantics(
      button: true,
      selected: selected,
      label: 'mi_courier'.tr(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: const Alignment(-0.6, -1),
              end: const Alignment(0.6, 1),
              colors: [tokens.primary, tokens.headerGradientEnd],
            ),
            // Contained in the bar now, so it no longer needs the ring that
            // punched it out of the dock; a soft glow is enough to lift it.
            boxShadow: BrandElevation.homeButton(tokens.primary),
          ),
          child: BrandGlyph(
            BrandIcons.receptions,
            color: tokens.onPrimary,
            size: 25,
          ),
        ),
      ),
    );
  }
}

/// One entry of the home quick action grid.
class QuickAction {
  const QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  final String label;

  /// Path of the brand glyph rendered as a tinted mask.
  final String icon;
  final VoidCallback onTap;
  final bool enabled;
}

/// Two-column grid of quick actions, filtered by capability.
class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({super.key, required this.actions});

  final List<QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final visible = actions.where((action) => action.enabled).toList();
    if (visible.isEmpty) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final width = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final action in visible)
              SizedBox(
                width: width,
                child: Semantics(
                  button: true,
                  label: action.label,
                  child: BrandCard(
                    onTap: action.onTap,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BrandGlyphTile(asset: action.icon),
                        const SizedBox(height: 10),
                        Text(
                          action.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: tokens.body(13, weight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Single source of the label and colour of a package state.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.stage,
    this.retained = false,
    this.available = false,
  }) : _soft = false;

  /// Tinted variant used inside list cards.
  const StatusBadge.soft({
    super.key,
    required this.stage,
    this.retained = false,
    this.available = false,
  }) : _soft = true;

  final PackageStage stage;
  final bool retained;
  final bool available;
  final bool _soft;

  bool get _isAvailable => available || stage == PackageStage.disponible;

  String get labelKey {
    if (stage == PackageStage.entregado) return 'entregado';
    if (_isAvailable && retained) return 'retenido';
    if (_isAvailable) return 'disponibles';
    return switch (stage) {
      PackageStage.origen => 'recibido',
      PackageStage.ruta => 'en_ruta',
      _ => 'en_destino',
    };
  }

  Color _fill(BrandTokens tokens) {
    if (stage == PackageStage.entregado) return tokens.success;
    if (_isAvailable && retained) return tokens.warning;
    if (_isAvailable) return tokens.primary;
    return tokens.surfaceAlt;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final fill = _fill(tokens);
    final neutral = fill == tokens.surfaceAlt;

    if (_soft) {
      final accent = neutral ? tokens.textMuted : fill;
      return BrandPill(
        label: labelKey.tr(),
        background: tokens.accentWash(accent, 0.14),
        foreground: accent,
        uppercase: true,
        fontSize: 10,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      );
    }
    return BrandPill(
      label: labelKey.tr(),
      background: fill,
      foreground: neutral ? tokens.text : tokens.onAccent(fill),
      fontSize: 11,
    );
  }
}

/// Four-segment progress rail drawn inside a package card.
class StageRail extends StatelessWidget {
  const StageRail({super.key, required this.stage, this.retained = false});

  final PackageStage stage;
  final bool retained;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final accent = packageAccent(tokens, stage, retained);
    final active = stage == PackageStage.entregado ? 3 : stage.index;
    return Row(
      children: [
        for (var index = 0; index < 4; index++) ...[
          if (index > 0) const SizedBox(width: 5),
          Container(
            width: index == active ? 22 : 14,
            height: 4,
            decoration: BoxDecoration(
              color: index <= active ? accent : tokens.border,
              borderRadius: BorderRadius.circular(BrandShape.rail),
            ),
          ),
        ],
      ],
    );
  }
}

/// Four labelled macro steps shown on the package detail screen.
class MacroStepper extends StatelessWidget {
  const MacroStepper({super.key, required this.stage});

  final PackageStage stage;

  static const _glyphs = [
    BrandIcons.received,
    BrandIcons.shipped,
    BrandIcons.atDestination,
    BrandIcons.available,
  ];

  static const _labelKeys = ['origen', 'en_ruta', 'en_destino', 'disponibles'];

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final delivered = stage == PackageStage.entregado;
    final active = delivered ? 3 : stage.index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < 4; index++)
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index > active
                          ? tokens.surfaceAlt
                          : (index == 3 && delivered
                              ? tokens.success
                              : tokens.primary),
                    ),
                    child: BrandGlyph(
                      _glyphs[index],
                      size: 22,
                      color: index > active
                          ? tokens.textMuted
                          : tokens.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    (index == 3 && delivered ? 'entregado' : _labelKeys[index])
                        .tr(),
                    textAlign: TextAlign.center,
                    style: tokens.body(
                      9,
                      weight: FontWeight.w600,
                      color: tokens.textMuted,
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

/// Package summary row used by every list of receptions.
class PackageCard extends StatelessWidget {
  const PackageCard({
    super.key,
    required this.package,
    this.onTap,
    this.currency = r'$',
  });

  final Recepcion package;
  final VoidCallback? onTap;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final status = PackageStatusMapper.map(
      status: package.estatus,
      isAvailable: package.disponible,
      progress: package.progreso,
    );
    final title = package.contenido.isEmpty
        ? package.suplidor
        : package.contenido;
    final meta = [
      if (package.suplidor.isNotEmpty) package.suplidor,
      if (package.totalPeso.isNotEmpty) '${package.totalPeso} ${'lbs'.tr()}',
      if (package.fecha.isNotEmpty) package.fecha,
    ].join(' · ');

    return BrandCard(
      onTap: onTap,
      shadow: true,
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  package.numeroRastreo.isEmpty
                      ? package.recepcionID
                      : package.numeroRastreo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tokens.body(
                    11,
                    weight: FontWeight.w500,
                    color: tokens.textMuted,
                    letterSpacing: 0.22,
                  ),
                ),
              ),
              const SizedBox(width: BrandSpace.xs),
              StatusBadge.soft(
                stage: status.stage,
                retained: package.retenido,
                available: package.disponible,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tokens.body(16, weight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$currency${package.totalNeto}',
                style: tokens.body(15, weight: FontWeight.w700),
              ),
            ],
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              meta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tokens.body(12, color: tokens.textMuted),
            ),
          ],
          const SizedBox(height: BrandSpace.sm),
          StageRail(stage: status.stage, retained: package.retenido),
        ],
      ),
    );
  }
}

/// Vertical event rail; the newest event carries the accent glow.
class EventTimeline extends StatelessWidget {
  const EventTimeline({
    super.key,
    required this.events,
    required this.stage,
    this.retained = false,
    this.dotSize = 14,
    this.spacing = 20,
  });

  final List<Historia> events;
  final PackageStage stage;
  final bool retained;
  final double dotSize;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final accent = packageAccent(tokens, stage, retained);
    final sorted = [...events]
      ..sort((a, b) => _safeDate(b).compareTo(_safeDate(a)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < sorted.length; index++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TimelineRail(
                  accent: accent,
                  first: index == 0,
                  last: index == sorted.length - 1,
                  dotSize: dotSize,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: spacing),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sorted[index].nombreEstatus.isEmpty
                              ? sorted[index].ciudad
                              : sorted[index].nombreEstatus,
                          style: index == 0
                              ? tokens.body(15, weight: FontWeight.w700)
                              : tokens.body(14, weight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sorted[index].fecha,
                          style: tokens.body(11, color: tokens.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TimelineRail extends StatelessWidget {
  const _TimelineRail({
    required this.accent,
    required this.first,
    required this.last,
    required this.dotSize,
  });

  final Color accent;
  final bool first;
  final bool last;
  final double dotSize;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return SizedBox(
      width: dotSize + 10,
      child: Column(
        children: [
          const SizedBox(height: 2),
          Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: first ? accent : tokens.surface,
              border: Border.all(
                color: first ? accent : tokens.border,
                width: 2,
              ),
              boxShadow: first
                  ? [
                      BoxShadow(
                        color: tokens.timelineGlow(accent),
                        spreadRadius: 5,
                      ),
                    ]
                  : null,
            ),
          ),
          if (!last)
            Expanded(
              child: Container(
                width: 2,
                constraints: const BoxConstraints(minHeight: 24),
                color: tokens.border,
              ),
            ),
        ],
      ),
    );
  }
}

/// Selectable availability row; retained packages are dimmed and locked.
class SelectableRow extends StatelessWidget {
  const SelectableRow({
    super.key,
    required this.package,
    required this.checked,
    required this.onToggle,
    this.onOpen,
    this.currency = r'$',
  });

  final Recepcion package;
  final bool checked;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onOpen;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final locked = package.retenido;
    return BrandCard(
      opacity: locked ? 0.75 : 1,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                checked: checked,
                enabled: !locked,
                label: package.contenido,
                child: GestureDetector(
                  onTap: locked ? null : () => onToggle(!checked),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: checked && !locked
                              ? tokens.primary
                              : tokens.surface,
                          border: Border.all(
                            color: checked && !locked
                                ? tokens.primary
                                : tokens.border,
                            width: 2,
                          ),
                          borderRadius:
                              BorderRadius.circular(BrandShape.checkbox),
                        ),
                        child: checked && !locked
                            ? Icon(
                                Icons.check,
                                size: 14,
                                color: tokens.onAccent(tokens.primary),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: onOpen,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        package.numeroRastreo.isEmpty
                            ? package.recepcionID
                            : package.numeroRastreo,
                        style: tokens.body(11, color: tokens.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        package.contenido.isEmpty
                            ? package.suplidor
                            : package.contenido,
                        style: tokens.body(15, weight: FontWeight.w700),
                      ),
                      if (package.suplidor.isNotEmpty ||
                          package.fecha.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          [
                            if (package.suplidor.isNotEmpty) package.suplidor,
                            if (package.fecha.isNotEmpty) package.fecha,
                          ].join(' · '),
                          style: tokens.body(12, color: tokens.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: BrandSpace.xs),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  '$currency${package.totalNeto}',
                  style: tokens.body(14, weight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (locked) ...[
            const SizedBox(height: BrandSpace.xs),
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
                    'sin_factura_no_elegible'.tr(),
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
      ),
    );
  }
}

/// Totals and actions for the current availability selection.
class SelectionSummaryBar extends StatelessWidget {
  const SelectionSummaryBar({
    super.key,
    required this.count,
    required this.total,
    required this.currency,
    required this.capabilities,
    this.onPickup,
    this.onPay,
    this.onDelivery,
    this.note,
  });

  final int count;
  final double total;
  final String currency;
  final BrandCapabilities capabilities;
  final VoidCallback? onPickup;
  final VoidCallback? onPay;
  final VoidCallback? onDelivery;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final hasPickup = onPickup != null;
    final hasPay = capabilities.payments && onPay != null;
    final hasDelivery = capabilities.delivery && onDelivery != null;
    if (!hasPickup && !hasPay && !hasDelivery) {
      return const SizedBox.shrink();
    }
    return ColoredBox(
      color: tokens.surfaceAlt,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BrandSpace.lg,
          vertical: BrandSpace.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Total(label: 'cantidad'.tr(), value: '$count'),
                const Spacer(),
                _Total(
                  label: 'total'.tr(),
                  value: '$currency${total.toStringAsFixed(2)}',
                  alignEnd: true,
                ),
              ],
            ),
            const SizedBox(height: BrandSpace.sm),
            Row(
              children: [
                if (hasPickup)
                  Expanded(
                    child: BrandOutlineButton(
                      label: 'retirar'.tr(),
                      onPressed: count == 0 ? null : onPickup,
                    ),
                  ),
                if (hasPickup && (hasPay || hasDelivery))
                  const SizedBox(width: 10),
                if (hasPay)
                  Expanded(
                    child: BrandOutlineButton(
                      label: 'pagar_ahora'.tr(),
                      onPressed: count == 0 ? null : onPay,
                    ),
                  ),
                if (hasPay && hasDelivery) const SizedBox(width: 10),
                if (hasDelivery)
                  Expanded(
                    child: BrandPrimaryButton(
                      label: 'domicilio'.tr(),
                      onPressed: count == 0 ? null : onDelivery,
                      fontSize: 13,
                      verticalPadding: 11,
                    ),
                  ),
              ],
            ),
            if (note != null) ...[
              const SizedBox(height: BrandSpace.xs),
              Text(
                note!,
                style: tokens.body(10, color: tokens.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: tokens.body(11, color: tokens.textMuted)),
        Text(value, style: tokens.head(20)),
      ],
    );
  }
}

/// Collapsible summary of receptions grouped by macro state.
class GroupRow extends StatelessWidget {
  const GroupRow({
    super.key,
    required this.label,
    required this.count,
    required this.onTap,
  });

  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    if (count == 0) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Material(
        color: tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(tokens.radiusSm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(tokens.radiusSm),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            child: Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: label,
                      style: tokens.body(13, weight: FontWeight.w600),
                      children: [
                        TextSpan(
                          text: ' ($count)',
                          style: tokens.body(
                            13,
                            weight: FontWeight.w700,
                            color: tokens.textMuted,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const BrandChevron(size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _tabLabel(TabModule module) => switch (module) {
      TabModule.news => 'noticias'.tr(),
      TabModule.branches => 'sucursales'.tr(),
      TabModule.home => 'mi_courier'.tr(),
      TabModule.calculator => 'calculadora'.tr(),
      TabModule.more => 'informacion_adicional'.tr(),
      TabModule.services => 'servicios'.tr(),
    };

String _tabGlyph(TabModule module) => switch (module) {
      TabModule.news => BrandIcons.news,
      TabModule.branches => BrandIcons.branches,
      TabModule.home => BrandIcons.receptions,
      TabModule.calculator => BrandIcons.calculator,
      TabModule.more => BrandIcons.information,
      TabModule.services => BrandIcons.services,
    };

DateTime _safeDate(Historia event) {
  try {
    return event.dateTime();
  } on FormatException {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
