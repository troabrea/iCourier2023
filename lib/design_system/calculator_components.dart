import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/brand_tokens.dart';
import 'brand_foundations.dart';

/// Product selector drawn as a dropdown.
///
/// The product name carries the meaning, so the control shows the current
/// choice inline instead of spending a row on a separate field label.
class ProductSelector<T> extends StatelessWidget {
  const ProductSelector({
    super.key,
    required this.options,
    required this.value,
    required this.labelFor,
    required this.onChange,
  });

  final List<T> options;
  final T value;
  final String Function(T option) labelFor;
  final ValueChanged<T> onChange;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(tokens.radiusSm),
      borderSide: BorderSide(color: tokens.border),
    );
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      style: tokens.body(12, weight: FontWeight.w700, color: tokens.text),
      dropdownColor: tokens.surface,
      borderRadius: BorderRadius.circular(tokens.radiusSm),
      icon: Icon(Icons.expand_more, color: tokens.textMuted),
      items: options
          .map(
            (option) => DropdownMenuItem<T>(
              value: option,
              child: Text(labelFor(option), overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(growable: false),
      onChanged: (selected) => onChange(selected ?? value),
      decoration: InputDecoration(
        filled: true,
        fillColor: tokens.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusSm),
          borderSide: BorderSide(color: tokens.primary, width: 2),
        ),
      ),
    );
  }
}

/// Large numeric entry with a fixed unit and no native steppers.
class BigNumberField extends StatelessWidget {
  const BigNumberField({
    super.key,
    required this.label,
    required this.unit,
    required this.controller,
    this.onChanged,
    this.unitLeading = false,
    this.hint = '0.00',
  });

  final String label;
  final String unit;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  /// Currency units sit before the number; weight units sit after it.
  final bool unitLeading;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final unitLabel = Text(
      unit,
      style: tokens.body(12, weight: FontWeight.w600, color: tokens.textMuted),
    );
    final field = TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      style: tokens.head(22),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: tokens.head(22, color: tokens.textMuted),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );

    return BrandCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.toUpperCase(), style: tokens.eyebrow(10)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (unitLeading) ...[
                unitLabel,
                const SizedBox(width: 5),
              ],
              Expanded(child: field),
              if (!unitLeading) ...[
                const SizedBox(width: 5),
                unitLabel,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// One line of the quote breakdown.
class CalcConceptView {
  const CalcConceptView({
    required this.label,
    required this.amount,
    this.quantity = '',
    this.unitPrice = '',
  });

  final String label;
  final double amount;
  final String quantity;
  final String unitPrice;
}

/// Subtotal, tax and total, shown above the breakdown so no scrolling is
/// needed to read the number the customer came for.
class TotalsPanel extends StatelessWidget {
  const TotalsPanel({
    super.key,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.currency,
  });

  final double subtotal;
  final double tax;
  final double total;
  final String currency;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _TotalTile(
                label: 'subtotal'.tr(),
                value: '$currency${_money(subtotal)}',
              ),
            ),
            const SizedBox(width: BrandSpace.xs),
            Expanded(
              child: _TotalTile(
                label: 'impuestos'.tr(),
                value: '$currency${_money(tax)}',
              ),
            ),
            const SizedBox(width: BrandSpace.xs),
            Expanded(
              // The total is the number they came for, so it gets twice the
              // width — but the other two still need room for their labels.
              flex: 2,
              child: _TotalTile(
                label: 'total'.tr(),
                value: '$currency${_money(total)}',
                emphasized: true,
              ),
            ),
          ],
        ),
      );
}

class _TotalTile extends StatelessWidget {
  const _TotalTile({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final radius = BorderRadius.circular(tokens.radiusSm);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: emphasized ? tokens.primary : tokens.border,
        ),
        borderRadius: radius,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              color: tokens.primary,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: tokens.body(
                  10,
                  weight: FontWeight.w700,
                  color: tokens.onAccent(tokens.primary),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              color: emphasized ? tokens.surfaceAlt : tokens.surface,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: tokens.head(
                    emphasized ? 15 : 13,
                    color: emphasized ? tokens.primary : tokens.text,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Itemised quote breakdown.
class ConceptTable extends StatelessWidget {
  const ConceptTable({
    super.key,
    required this.concepts,
    required this.currency,
    this.weightUnit = 'lbs',
  });

  final List<CalcConceptView> concepts;
  final String currency;
  final String weightUnit;

  static const _columns = <int, TableColumnWidth>{
    0: FlexColumnWidth(1.6),
    1: FlexColumnWidth(0.6),
    2: FlexColumnWidth(0.8),
    3: FlexColumnWidth(0.9),
  };

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    if (concepts.isEmpty) {
      return const SizedBox.shrink();
    }
    return BrandCard(
      clip: true,
      margin: const EdgeInsets.only(bottom: 10),
      child: Table(
        columnWidths: _columns,
        defaultVerticalAlignment: TableCellVerticalAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          TableRow(
            decoration: BoxDecoration(color: tokens.surfaceAlt),
            children: [
              _HeadCell('concepto'.tr()),
              _HeadCell(weightUnit),
              _HeadCell('unitario'.tr(), alignEnd: true),
              _HeadCell('total'.tr(), alignEnd: true),
            ],
          ),
          for (final concept in concepts)
            TableRow(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: tokens.border)),
              ),
              children: [
                _BodyCell(
                  concept.label,
                  weight: FontWeight.w500,
                  muted: true,
                ),
                _BodyCell(concept.quantity, weight: FontWeight.w600),
                _BodyCell(
                  concept.unitPrice,
                  weight: FontWeight.w600,
                  alignEnd: true,
                ),
                _BodyCell(
                  '$currency${_money(concept.amount)}',
                  weight: FontWeight.w700,
                  size: 12,
                  alignEnd: true,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _HeadCell extends StatelessWidget {
  const _HeadCell(this.label, {this.alignEnd = false});

  final String label;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Text(
        label.toUpperCase(),
        textAlign: alignEnd ? TextAlign.right : TextAlign.left,
        style: tokens.eyebrow(9).copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  const _BodyCell(
    this.value, {
    this.weight = FontWeight.w400,
    this.size = 11,
    this.muted = false,
    this.alignEnd = false,
  });

  final String value;
  final FontWeight weight;
  final double size;
  final bool muted;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Text(
        value,
        textAlign: alignEnd ? TextAlign.right : TextAlign.left,
        style: tokens.body(
          size,
          weight: weight,
          color: muted ? tokens.textMuted : tokens.text,
        ),
      ),
    );
  }
}

String _money(double value) => value.toStringAsFixed(2);
