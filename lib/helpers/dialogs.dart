import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icourier/services/model/recepcion.dart';

import '../design_system/brand_foundations.dart';
import '../design_system/overlay_components.dart';
import '../theme/brand_tokens.dart';

/// Confirmation prompt used by the dashboard flows.
///
/// The signatures here are kept as they were so the blocs that call them stay
/// untouched; only the presentation moved onto the brand dialog and sheets.
Future<bool> confirmDialog(
  BuildContext context,
  String message,
  String okButtonText,
  String cancelButtonText,
) =>
    ConfirmDialog.show(
      context,
      title: 'confirme'.tr(),
      message: message,
      confirmLabel: okButtonText,
    );

/// Single-choice prompt, used to pick where a package will be collected.
///
/// Returns the chosen label, or `Cancelar` when dismissed.
Future<String> optionsDialog(
  BuildContext context,
  String message,
  List<String> optionsText,
) async {
  // The trailing entry is the caller's cancel label; dismissing the sheet has
  // the same effect, so it is not drawn as an option.
  final cancelLabel = optionsText.isEmpty ? 'cancelar'.tr() : optionsText.last;
  final options = optionsText.length > 1
      ? optionsText.sublist(0, optionsText.length - 1)
      : const <String>[];

  final result = await showBrandSheet<String>(
    context,
    child: _OptionsSheet(message: message, options: options),
  );
  return result ?? cancelLabel;
}

class _OptionsSheet extends StatefulWidget {
  const _OptionsSheet({required this.message, required this.options});

  final String message;
  final List<String> options;

  @override
  State<_OptionsSheet> createState() => _OptionsSheetState();
}

class _OptionsSheetState extends State<_OptionsSheet> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) => BrandSheet(
        title: 'notificar_retiro'.tr(),
        subtitle: widget.message,
        children: [
          Row(
            children: [
              for (var index = 0; index < widget.options.length; index++) ...[
                if (index > 0) const SizedBox(width: 10),
                Expanded(
                  child: BrandOutlineButton(
                    label: widget.options[index],
                    selected: index == _selected,
                    verticalPadding: 12,
                    onPressed: () => setState(() => _selected = index),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: BrandSpace.md),
          BrandPrimaryButton(
            label: 'confirmar'.tr(),
            onPressed: widget.options.isEmpty
                ? null
                : () => Navigator.of(context).pop(widget.options[_selected]),
          ),
        ],
      );
}

/// Home delivery confirmation.
///
/// The previous picker rendered disabled checkboxes, so every available package
/// was always submitted; the design reference confirms the whole set instead of
/// offering a selection, which is what this now does explicitly.
Future<List<String>> domicilioDialog(
  BuildContext context,
  String message,
  String okButtonText,
  String cancelButtonText,
  List<Recepcion> disponibles,
) async {
  final result = await showBrandSheet<bool>(
    context,
    scrollable: true,
    child: _DeliveryConfirmSheet(
      message: message,
      confirmLabel: okButtonText,
      disponibles: disponibles,
    ),
  );
  return (result ?? false)
      ? disponibles.map((package) => package.recepcionID).toList(growable: false)
      : const <String>[];
}

class _DeliveryConfirmSheet extends StatelessWidget {
  const _DeliveryConfirmSheet({
    required this.message,
    required this.confirmLabel,
    required this.disponibles,
  });

  final String message;
  final String confirmLabel;
  final List<Recepcion> disponibles;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return BrandSheet(
      title: 'solicitar_domicilio'.tr(),
      subtitle: message,
      maxHeightFactor: 0.78,
      children: [
        for (final package in disponibles)
          Padding(
            padding: const EdgeInsets.only(bottom: BrandSpace.xs),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    package.contenido.isEmpty
                        ? package.suplidor
                        : package.contenido,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tokens.body(13, weight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: BrandSpace.xs),
                Text(
                  package.totalNeto,
                  style: tokens.body(13, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
        const SizedBox(height: BrandSpace.xs),
        BrandPrimaryButton(
          label: confirmLabel,
          onPressed: disponibles.isEmpty
              ? null
              : () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
