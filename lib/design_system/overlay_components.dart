import 'package:barcode_widget/barcode_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/model/login_model.dart';
import '../services/model/sucursal.dart';
import '../theme/brand_config.dart';
import '../theme/brand_tokens.dart';
import 'brand_foundations.dart';
import 'core_components.dart';

/// Presents [child] as a modal sheet with the brand scrim and corner radius.
Future<T?> showBrandSheet<T>(
  BuildContext context, {
  required Widget child,
  bool scrollable = false,
}) {
  final tokens = context.brand;
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: tokens.surface,
    barrierColor: tokens.modalScrim,
    isScrollControlled: scrollable,
    // A scroll-controlled sheet may grow to the full screen, and without this
    // it would run under the status bar and the notch.
    useSafeArea: scrollable,
    // Presented above the shell, so the floating tab bar does not sit on top
    // of the sheet's own content and actions.
    useRootNavigator: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(BrandShape.sheet),
      ),
    ),
    builder: (context) => child,
  );
}

/// Panel shell for every bottom sheet: grabber, title and content.
class BrandSheet extends StatelessWidget {
  const BrandSheet({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.maxHeightFactor,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final double? maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    // Header stays out of the scroll area: on a tall sheet the grabber would
    // otherwise scroll away, leaving no visible way back.
    final header = <Widget>[
      const BrandSheetGrabber(),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: tokens.head(17)),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: tokens.body(13, color: tokens.textMuted),
                  ),
                ],
              ],
            ),
          ),
          Semantics(
            button: true,
            label: 'cerrar'.tr(),
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.close, size: 20, color: tokens.textMuted),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: BrandSpace.md),
    ];

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );

    final Widget content = maxHeightFactor == null
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [...header, body],
          )
        : ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * maxHeightFactor!,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...header,
                Flexible(child: SingleChildScrollView(child: body)),
              ],
            ),
          );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BrandSpace.lg,
          BrandSpace.lg,
          BrandSpace.lg,
          BrandSpace.md,
        ),
        child: content,
      ),
    );
  }
}

/// The short bar that signals a sheet can be dragged away.
class BrandSheetGrabber extends StatelessWidget {
  const BrandSheetGrabber({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Padding(
      padding: const EdgeInsets.only(bottom: BrandSpace.md),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: tokens.border,
            borderRadius: BorderRadius.circular(BrandShape.rail),
          ),
        ),
      ),
    );
  }
}

/// Sheet that confirms where the customer will collect their packages.
class PickupSheet extends StatefulWidget {
  const PickupSheet({
    super.key,
    required this.modes,
    required this.count,
    required this.onConfirm,
  });

  final List<BrandPickupMode> modes;
  final int count;
  final ValueChanged<BrandPickupMode?> onConfirm;

  @override
  State<PickupSheet> createState() => _PickupSheetState();
}

class _PickupSheetState extends State<PickupSheet> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) => BrandSheet(
        title: 'notificar_retiro'.tr(),
        subtitle: widget.modes.isEmpty
            ? 'seguro_notificar_retiro'.tr()
            : 'donde_retirar_paquetes'.tr(args: ['${widget.count}']),
        children: [
          if (widget.modes.isNotEmpty) ...[
            Row(
              children: [
                for (var index = 0; index < widget.modes.length; index++) ...[
                  if (index > 0) const SizedBox(width: 10),
                  Expanded(
                    child: BrandOutlineButton(
                      label: widget.modes[index].label,
                      selected: index == _selected,
                      verticalPadding: 12,
                      onPressed: () => setState(() => _selected = index),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: BrandSpace.md),
          ],
          BrandPrimaryButton(
            label: 'confirmar'.tr(),
            onPressed: () {
              Navigator.of(context).pop();
              widget.onConfirm(
                widget.modes.isEmpty ? null : widget.modes[_selected],
              );
            },
          ),
        ],
      );
}

/// Sheet that hands the customer over to the brand payment gateway.
class PaymentSheet extends StatelessWidget {
  const PaymentSheet({
    super.key,
    required this.amount,
    required this.brandName,
    required this.onConfirm,
  });

  final String amount;
  final String brandName;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) => BrandSheet(
        title: 'pagar'.tr(args: [amount]),
        subtitle: 'pasarela_pago_segura'.tr(args: [brandName]),
        children: [
          BrandPrimaryButton(
            label: 'pagar_ahora'.tr(),
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
          ),
        ],
      );
}

/// Sheet that confirms a home delivery request.
class DeliverySheet extends StatelessWidget {
  const DeliverySheet({
    super.key,
    required this.count,
    required this.onConfirm,
  });

  final int count;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) => BrandSheet(
        title: 'solicitar_domicilio'.tr(),
        subtitle: 'recibira_n_paquetes'.tr(args: ['$count']),
        children: [
          BrandPrimaryButton(
            label: 'confirmar_solicitud'.tr(),
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
          ),
        ],
      );
}

/// Branch detail sheet with its contact actions.
class BranchSheet extends StatelessWidget {
  const BranchSheet({
    super.key,
    required this.branch,
    this.whatsapp = '',
    this.onCall,
    this.onWhatsApp,
    this.onEmail,
    this.onDirections,
  });

  final Sucursal branch;

  /// Number reported by the profile; the branch record does not carry one.
  final String whatsapp;
  final VoidCallback? onCall;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onEmail;
  final VoidCallback? onDirections;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: BrandSpace.sm),
                child: BrandSheetGrabber(),
              ),
              ColoredBox(
                color: tokens.primary,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    BrandSpace.lg,
                    14,
                    BrandSpace.lg,
                    BrandSpace.md,
                  ),
                  child: Text(
                    branch.nombre,
                    style: tokens.head(18, color: tokens.onPrimary),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: tokens.border)),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    _BranchAction(
                      glyph: BrandIcons.phone,
                      label: 'llamar'.tr(),
                      onTap: onCall,
                    ),
                    if (whatsapp.isNotEmpty)
                      _BranchAction(
                        glyph: BrandIcons.whatsapp,
                        label: 'whatsapp'.tr(),
                        onTap: onWhatsApp,
                      ),
                    _BranchAction(
                      glyph: BrandIcons.email,
                      label: 'email'.tr(),
                      onTap: onEmail,
                    ),
                    _BranchAction(
                      glyph: BrandIcons.mapMarker,
                      label: 'navegar'.tr(),
                      onTap: onDirections,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  BrandSpace.lg,
                  BrandSpace.md,
                  BrandSpace.lg,
                  30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BranchDetail(
                      glyph: BrandIcons.mapMarker,
                      value: branch.direccion,
                    ),
                    _BranchDetail(
                      glyph: BrandIcons.email,
                      value: branch.email,
                    ),
                    _BranchDetail(
                      glyph: BrandIcons.phone,
                      value: branch.telefonoOficina,
                    ),
                    _BranchDetail(
                      glyph: BrandIcons.whatsapp,
                      value: whatsapp,
                    ),
                    _BranchDetail(
                      glyph: BrandIcons.schedule,
                      value: branch.horario,
                      last: true,
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

class _BranchAction extends StatelessWidget {
  const _BranchAction({
    required this.glyph,
    required this.label,
    this.onTap,
  });

  final String glyph;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        child: InkResponse(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BrandGlyph(glyph, color: tokens.primary, size: 20),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: tokens.body(
                    10,
                    weight: FontWeight.w600,
                    color: tokens.textMuted,
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

class _BranchDetail extends StatelessWidget {
  const _BranchDetail({
    required this.glyph,
    required this.value,
    this.last = false,
  });

  final String glyph;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : BrandSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: BrandGlyph(glyph, color: tokens.textMuted, size: 16),
          ),
          const SizedBox(width: BrandSpace.sm),
          Expanded(child: Text(value, style: tokens.body(13))),
        ],
      ),
    );
  }
}

/// Destructive confirmation drawn with the brand dialog shape.
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    this.confirmLabel,
    this.destructive = false,
  });

  final String title;
  final String message;
  final VoidCallback onConfirm;
  final String? confirmLabel;
  final bool destructive;

  /// Shows the dialog and resolves to `true` when the action was confirmed.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmLabel,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: context.brand.modalScrim,
      builder: (context) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        destructive: destructive,
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return AlertDialog(
      backgroundColor: tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusLg),
      ),
      title: Text(title, style: tokens.head(17)),
      content: Text(message, style: tokens.body(13, color: tokens.textMuted)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'cancelar'.tr(),
            style: tokens.body(13, weight: FontWeight.w700),
          ),
        ),
        BrandPrimaryButton(
          label: confirmLabel ?? 'aceptar'.tr(),
          expand: false,
          fontSize: 13,
          verticalPadding: 10,
          background: destructive ? tokens.danger : tokens.primary,
          onPressed: onConfirm,
        ),
      ],
    );
  }
}

/// Account switcher sheet: change, add or remove a linked account.
class AccountSwitcher extends StatefulWidget {
  const AccountSwitcher({
    super.key,
    required this.accounts,
    required this.activeAccount,
    required this.onSelect,
    required this.onDelete,
    required this.onAdd,
  });

  final List<UserAccount> accounts;
  final String activeAccount;
  final ValueChanged<UserAccount> onSelect;
  final ValueChanged<UserAccount> onDelete;
  final VoidCallback onAdd;

  @override
  State<AccountSwitcher> createState() => _AccountSwitcherState();
}

class _AccountSwitcherState extends State<AccountSwitcher> {
  String? _pendingDelete;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return BrandSheet(
      title: 'sus_cuentas'.tr(),
      maxHeightFactor: 0.78,
      children: [
        for (final account in widget.accounts)
          _AccountRow(
            account: account,
            active: account.userAccount == widget.activeAccount,
            confirming: _pendingDelete == account.userAccount,
            onSelect: () => widget.onSelect(account),
            onAskDelete: () =>
                setState(() => _pendingDelete = account.userAccount),
            onCancelDelete: () => setState(() => _pendingDelete = null),
            onConfirmDelete: () {
              widget.onDelete(account);
              setState(() => _pendingDelete = null);
            },
          ),
        // One action, because it is one flow: both signing in with another
        // account and signing out release the current session.
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: DottedBorderBox(
            child: TextButton(
              onPressed: widget.onAdd,
              style: TextButton.styleFrom(
                foregroundColor: tokens.primary,
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.symmetric(vertical: BrandSpace.sm),
                textStyle: tokens.body(13, weight: FontWeight.w700),
              ),
              child: Text('cambiar_cuenta_o_cerrar_session'.tr()),
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.account,
    required this.active,
    required this.confirming,
    required this.onSelect,
    required this.onAskDelete,
    required this.onCancelDelete,
    required this.onConfirmDelete,
  });

  final UserAccount account;
  final bool active;
  final bool confirming;
  final VoidCallback onSelect;
  final VoidCallback onAskDelete;
  final VoidCallback onCancelDelete;
  final VoidCallback onConfirmDelete;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final name = account.nombre.trim();
    return BrandCard(
      color: tokens.surfaceAlt,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onSelect,
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tokens.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    name.isEmpty ? '' : name.characters.first.toUpperCase(),
                    style: tokens.head(
                      14,
                      color: tokens.onAccent(tokens.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: onSelect,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tokens.body(13, weight: FontWeight.w700),
                      ),
                      Text(
                        account.userAccount,
                        style: tokens.body(11, color: tokens.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
              if (active)
                BrandPill(
                  label: 'activa'.tr(),
                  background: tokens.primary,
                  foreground: tokens.onAccent(tokens.primary),
                  fontSize: 10,
                ),
              // Offered on the active account too: forgetting the one you are
              // signed in with is how you sign out of it for good.
              IconButton(
                onPressed: onAskDelete,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: tokens.danger,
                ),
                tooltip: 'confirme_borrar_cuenta'.tr(),
              ),
            ],
          ),
          if (confirming) ...[
            const SizedBox(height: 10),
            Divider(height: 1, color: tokens.border),
            const SizedBox(height: 10),
            Text(
              'confirme_borrar_cuenta'.tr(),
              style: tokens.body(
                12,
                weight: FontWeight.w600,
                color: tokens.danger,
              ),
            ),
            const SizedBox(height: 10),
            // The two answers sit at opposite ends: side by side, a finger
            // aiming for "no" lands on the destructive one.
            Row(
              children: [
                _HoldToConfirm(onConfirm: onConfirmDelete),
                const Spacer(),
                BrandOutlineButton(
                  label: 'no'.tr(),
                  expand: false,
                  fontSize: 11,
                  verticalPadding: 6,
                  onPressed: onCancelDelete,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Destructive confirmation that only fires once the finger has been held
/// down, so a slip while reaching for "no" cannot forget an account.
///
/// The hold guards fingers, not intent: assistive technology activates it as a
/// plain button, since a screen reader already takes two deliberate steps to
/// reach and trigger a control.
class _HoldToConfirm extends StatefulWidget {
  const _HoldToConfirm({required this.onConfirm});

  final VoidCallback onConfirm;

  @override
  State<_HoldToConfirm> createState() => _HoldToConfirmState();
}

class _HoldToConfirmState extends State<_HoldToConfirm>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    reverseDuration: const Duration(milliseconds: 160),
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.heavyImpact();
        widget.onConfirm();
      }
    });

  /// Confirming removes the row this button lives in, so the finger comes up
  /// after the controller is already gone.
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _progress.dispose();
    super.dispose();
  }

  void _release() {
    if (_disposed) {
      return;
    }
    _progress.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final radius = BorderRadius.circular(tokens.radiusSm);
    final foreground = tokens.onAccent(tokens.danger);
    return Semantics(
      button: true,
      label: 'si_eliminar'.tr(),
      onTap: widget.onConfirm,
      excludeSemantics: true,
      child: Listener(
        onPointerDown: (_) => _progress.forward(),
        onPointerUp: (_) => _release(),
        onPointerCancel: (_) => _release(),
        child: ClipRRect(
          borderRadius: radius,
          child: ColoredBox(
            color: tokens.danger,
            child: Stack(
              children: [
                // Fills left to right while held, so the wait reads as
                // progress rather than an unresponsive button.
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _progress,
                    builder: (context, child) => FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _progress.value,
                      child: ColoredBox(
                        color: foreground.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        'sostener_para_eliminar'.tr(),
                        style: tokens.body(
                          11,
                          weight: FontWeight.w700,
                          color: foreground,
                        ),
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
}

/// One-time onboarding hint shown on the home screen.
class TipBubble extends StatelessWidget {
  const TipBubble({
    super.key,
    required this.title,
    required this.message,
    this.onDismiss,
  });

  final String title;
  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return BrandCard(
      color: tokens.surfaceAlt,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tokens.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.info_outline,
              size: 15,
              color: tokens.onAccent(tokens.primary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: tokens.body(13, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: tokens.body(12, color: tokens.textMuted),
                ),
                if (onDismiss != null)
                  Padding(
                    padding: const EdgeInsets.only(top: BrandSpace.xs),
                    child: GestureDetector(
                      onTap: onDismiss,
                      child: Text(
                        'entendido'.tr(),
                        style: tokens.body(
                          12,
                          weight: FontWeight.w700,
                          color: tokens.primary,
                        ),
                      ),
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

/// Membership QR rendered on the brand carnet.
class CarnetQR extends StatelessWidget {
  const CarnetQR({super.key, required this.accountCode});

  final String accountCode;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Semantics(
      label: accountCode,
      image: true,
      child: Container(
        width: 150,
        height: 150,
        padding: const EdgeInsets.all(BrandSpace.sm),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(BrandShape.qr),
        ),
        child: BarcodeWidget(
          barcode: Barcode.qrCode(),
          data: accountCode,
          drawText: false,
          color: tokens.text,
          backgroundColor: tokens.surface,
        ),
      ),
    );
  }
}

/// Quick actions that step aside when the screen is busy.
///
/// The packages card, the banner and the tab bar own the first screen; these
/// are secondary by definition, so when what is left will not hold the rows
/// they fold into one button that opens them in a sheet. The rows themselves
/// never shrink or reflow — they are either there or behind the button.
class AdaptiveQuickActions extends StatelessWidget {
  const AdaptiveQuickActions({
    super.key,
    required this.actions,
    required this.room,
  });

  final List<QuickAction> actions;

  /// Vertical space left on the first screen once everything that must stay
  /// visible has taken its share.
  final double room;

  @override
  Widget build(BuildContext context) {
    final visible = actions.where((action) => action.enabled).toList();
    if (visible.isEmpty) {
      return const SizedBox.shrink();
    }
    if (room >= QuickActionList.heightFor(visible.length)) {
      return QuickActionList(actions: visible);
    }
    return BrandOutlineButton(
      label: 'acciones_rapidas'.tr(),
      icon: const Icon(Icons.grid_view_rounded, size: 18),
      // Scroll-controlled on purpose: this only folds on short screens, which
      // are exactly the ones where the list would not fit the sheet either.
      onPressed: () => showBrandSheet<void>(
        context,
        scrollable: true,
        child: _QuickActionSheet(actions: visible),
      ),
    );
  }
}

class _QuickActionSheet extends StatelessWidget {
  const _QuickActionSheet({required this.actions});

  final List<QuickAction> actions;

  @override
  Widget build(BuildContext context) => BrandSheet(
        title: 'acciones_rapidas'.tr(),
        maxHeightFactor: 0.7,
        children: [
          QuickActionList(
            actions: [
              for (final action in actions)
                QuickAction(
                  label: action.label,
                  icon: action.icon,
                  enabled: action.enabled,
                  onTap: () {
                    Navigator.of(context).pop();
                    action.onTap();
                  },
                ),
            ],
          ),
        ],
      );
}
