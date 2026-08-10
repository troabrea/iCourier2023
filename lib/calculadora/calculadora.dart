import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design_system/brand_foundations.dart';
import '../design_system/brand_states.dart';
import '../design_system/calculator_components.dart';
import '../design_system/core_components.dart';
import '../services/courier_service.dart';
import '../services/model/producto.dart';
import '../theme/brand_config.dart';
import '../theme/brand_tokens.dart';
import 'bloc/calculadora_bloc.dart';

class CalculadoraPage extends StatefulWidget {
  const CalculadoraPage({super.key});

  @override
  State<CalculadoraPage> createState() => _CalculadoraPageState();
}

class _CalculadoraPageState extends State<CalculadoraPage> {
  final _weightController = TextEditingController();
  final _valueController = TextEditingController(text: '0');
  late final CalculadoraBloc _bloc;
  late final BrandConfig _config;
  List<Producto> _products = const [];
  Producto? _selectedProduct;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    _config = GetIt.I<BrandConfig>();
    _weightController.text = _config.calculator.initialWeight.toString();
    _bloc = CalculadoraBloc(GetIt.I<CourierService>())
      ..add(CalculatorPrepareEvent());
  }

  @override
  void dispose() {
    _weightController.dispose();
    _valueController.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: ScreenHeader.tab(title: 'calculadora'.tr()),
      body: BlocProvider.value(
        value: _bloc,
        child: BlocBuilder<CalculadoraBloc, CalculadoraState>(
          builder: (context, state) {
            if (state is CalculadoraPreparedState) {
              _products = state.productos;
              _selectedProduct ??= state.productoDefault;
            }
            if (state is CalculadoraLoadingState && _products.isEmpty) {
              return const BrandSkeleton();
            }
            return SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  BrandSpace.lg,
                  18,
                  BrandSpace.lg,
                  BrandTabBar.height,
                ),
                children: [
                  // Weight and FOB sit side by side with fixed units and no
                  // native steppers, as the reference specifies.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: BigNumberField(
                          label: 'peso'.tr(),
                          unit: _config.weightUnit,
                          controller: _weightController,
                          hint: '0.0',
                          onChanged: (_) => _clearValidation(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: BigNumberField(
                          label: 'valor_fob'.tr(),
                          unit: _config.currency,
                          unitLeading: true,
                          controller: _valueController,
                          onChanged: (_) => _clearValidation(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: BrandSpace.md),
                  if (_products.length > 1) ...[
                    Text(
                      'producto'.tr(),
                      style: tokens.body(
                        12,
                        weight: FontWeight.w600,
                        color: tokens.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ProductSelector<Producto>(
                      options: _products,
                      value: _selectedProduct ?? _products.first,
                      labelFor: (product) => product.titulo,
                      onChange: (product) {
                        setState(() => _selectedProduct = product);
                      },
                    ),
                    const SizedBox(height: BrandSpace.md),
                  ],
                  if (_validationMessage != null) ...[
                    Text(
                      _validationMessage!,
                      style: tokens.body(
                        12,
                        weight: FontWeight.w600,
                        color: tokens.danger,
                      ),
                    ),
                    const SizedBox(height: BrandSpace.xs),
                  ],
                  BrandPrimaryButton(
                    label: 'calcular_envio'.tr(),
                    onPressed:
                        state is CalculadoraLoadingState ? null : _calculate,
                  ),
                  const SizedBox(height: 14),
                  if (state is CalculadoraLoadingState)
                    const BrandSkeleton(rows: 3)
                  else if (state is CalculadoraLoadedState)
                    _Result(state: state, config: _config)
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: BrandSpace.lg,
                      ),
                      child: Text(
                        'especifique_valores_toque_calcular'.tr(),
                        textAlign: TextAlign.center,
                        style: tokens.body(12, color: tokens.textMuted),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    final weight = double.tryParse(_weightController.text.replaceAll(',', ''));
    final value = double.tryParse(_valueController.text.replaceAll(',', ''));
    if (weight == null ||
        value == null ||
        weight < _config.calculator.minimumWeight ||
        value < 0) {
      setState(() => _validationMessage = 'mayor_de_cero'.tr());
      return;
    }
    setState(() => _validationMessage = null);
    _bloc.add(CalculateEvent(weight, value, _selectedProduct?.codigo ?? ''));
  }

  void _clearValidation() {
    if (_validationMessage != null) {
      setState(() => _validationMessage = null);
    }
  }
}

/// Totals first, then the breakdown: the customer should not scroll to reach
/// the number they came for.
class _Result extends StatelessWidget {
  const _Result({required this.state, required this.config});

  final CalculadoraLoadedState state;
  final BrandConfig config;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    if (state.resultados.isEmpty) {
      return const BrandEmptyState(
        messageKey: 'no_resultados',
        glyph: BrandIcons.calculator,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TotalsPanel(
          subtotal: state.subtotal,
          tax: state.impuestos,
          total: state.total,
          currency: config.currency,
        ),
        const SizedBox(height: BrandSpace.sm),
        ConceptTable(
          currency: config.currency,
          weightUnit: config.weightUnit,
          concepts: state.resultados
              .map(
                (result) => CalcConceptView(
                  label: result.productoNombre,
                  amount: result.neto,
                  quantity: result.cantidad.toStringAsFixed(2),
                  unitPrice: result.precio.toStringAsFixed(2),
                ),
              )
              .toList(growable: false),
        ),
        Text(
          'valores_en_moneda_sujeto_a_cambios'.tr(args: [config.currency]),
          textAlign: TextAlign.center,
          style: tokens.body(10, color: tokens.textMuted),
        ),
        if (state.valorFob >= 200)
          Padding(
            padding: const EdgeInsets.only(top: BrandSpace.xs),
            child: Text(
              'aviso_pago_aduanal'.tr(),
              style: tokens.body(10, color: tokens.textMuted),
            ),
          ),
        if (state.email.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: BrandSpace.xs),
            child: GestureDetector(
              onTap: () => launchUrl(
                Uri(scheme: 'mailto', path: state.email),
              ),
              child: Text(
                '${'aclaracion_estimado'.tr()}${state.email}',
                textAlign: TextAlign.center,
                style: tokens.body(10, color: tokens.primary),
              ),
            ),
          ),
      ],
    );
  }
}
