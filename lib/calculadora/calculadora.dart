import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design_system/brand_states.dart';
import '../design_system/calculator_components.dart';
import '../design_system/core_components.dart';
import '../services/courier_service.dart';
import '../services/model/producto.dart';
import '../theme/brand_config.dart';
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
    return Scaffold(
      appBar: ScreenHeader(title: 'calculadora'.tr()),
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                children: [
                  if (_products.length > 1) ...[
                    ProductSelector<Producto>(
                      options: _products,
                      value: _selectedProduct ?? _products.first,
                      labelFor: (product) => product.titulo,
                      onChange: (product) {
                        setState(() => _selectedProduct = product);
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                  BigNumberField(
                    label: 'libras'.tr(),
                    unit: _config.weightUnit,
                    controller: _weightController,
                    onChanged: (_) => _clearValidation(),
                  ),
                  const SizedBox(height: 20),
                  BigNumberField(
                    label: 'valor_fob'.tr(),
                    unit: _config.currency,
                    controller: _valueController,
                    onChanged: (_) => _clearValidation(),
                  ),
                  if (_validationMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _validationMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed:
                        state is CalculadoraLoadingState ? null : _calculate,
                    icon: const Icon(Icons.calculate_outlined),
                    label: Text('calcular_envio'.tr()),
                  ),
                  const SizedBox(height: 24),
                  if (state is CalculadoraLoadingState)
                    const BrandSkeleton(rows: 4)
                  else if (state is CalculadoraLoadedState) ...[
                    if (state.resultados.isEmpty)
                      const BrandEmptyState(messageKey: 'no_resultados')
                    else ...[
                      ConceptTable(
                        currency: _config.currency,
                        concepts: state.resultados
                            .map(
                              (result) => CalcConceptView(
                                label: result.productoNombre,
                                amount: result.neto,
                              ),
                            )
                            .toList(growable: false),
                      ),
                      const SizedBox(height: 16),
                      TotalsPanel(
                        subtotal: state.subtotal,
                        tax: state.impuestos,
                        total: state.total,
                        currency: _config.currency,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'valores_en_moneda_sujeto_a_cambios'
                            .tr(args: [_config.currency]),
                        textAlign: TextAlign.center,
                      ),
                      if (state.valorFob >= 200)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'aviso_pago_aduanal'.tr(),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      if (state.email.isNotEmpty)
                        TextButton(
                          onPressed: () => launchUrl(
                            Uri(scheme: 'mailto', path: state.email),
                          ),
                          child: Text(
                            '${'aclaracion_estimado'.tr()} ${state.email}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ] else
                    const BrandEmptyState(
                      messageKey: 'especifique_valores_toque_calcular',
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
