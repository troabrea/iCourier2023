import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/brand_tokens.dart';

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
    return SegmentedButton<T>(
      segments: options
          .map(
            (option) => ButtonSegment<T>(
              value: option,
              label: Text(labelFor(option)),
            ),
          )
          .toList(growable: false),
      selected: {value},
      onSelectionChanged: (selection) => onChange(selection.first),
    );
  }
}

class BigNumberField extends StatelessWidget {
  const BigNumberField({
    super.key,
    required this.label,
    required this.unit,
    required this.controller,
    this.onChanged,
  });

  final String label;
  final String unit;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      style: Theme.of(context).textTheme.displayMedium,
      decoration: InputDecoration(labelText: label, suffixText: unit),
      onChanged: onChanged,
    );
  }
}

class CalcConceptView {
  const CalcConceptView({required this.label, required this.amount});

  final String label;
  final double amount;
}

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
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.primary,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _TotalLine(
              label: 'subtotal'.tr(),
              value: _money(subtotal),
              currency: currency,
            ),
            const SizedBox(height: 8),
            _TotalLine(
              label: 'impuestos'.tr(),
              value: _money(tax),
              currency: currency,
            ),
            const Divider(),
            _TotalLine(
              label: 'total'.tr(),
              value: _money(total),
              currency: currency,
              emphasized: true,
            ),
          ],
        ),
      ),
    );
  }
}

class ConceptTable extends StatelessWidget {
  const ConceptTable({
    super.key,
    required this.concepts,
    required this.currency,
  });

  final List<CalcConceptView> concepts;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (final concept in concepts)
            ListTile(
              title: Text(concept.label),
              trailing: Text('$currency ${_money(concept.amount)}'),
            ),
        ],
      ),
    );
  }
}

class _TotalLine extends StatelessWidget {
  const _TotalLine({
    required this.label,
    required this.value,
    required this.currency,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final String currency;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final style = emphasized
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.bodyMedium;
    return Row(
      children: [
        Expanded(
            child:
                Text(label, style: style?.copyWith(color: tokens.onPrimary))),
        Text(
          '$currency $value',
          style: style?.copyWith(color: tokens.onPrimary),
        ),
      ],
    );
  }
}

String _money(double value) => value.toStringAsFixed(2);
