import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design_system/brand_foundations.dart';
import '../design_system/brand_states.dart';
import '../design_system/calculator_components.dart';
import '../design_system/core_components.dart';
import '../design_system/motion_components.dart';
import '../helpers/contact_action.dart';
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
  bool _quoteIsStale = true;

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
      appBar: ScreenHeader.tab(
        title: 'calculadora'.tr(),
        trailing: const BrandContactAction(),
      ),
      body: BlocProvider.value(
        value: _bloc,
        child: BlocConsumer<CalculadoraBloc, CalculadoraState>(
          listener: (context, state) {
            if (state is CalculadoraLoadedState &&
                state.resultados.isNotEmpty &&
                !_quoteIsStale) {
              HapticFeedback.lightImpact();
            }
          },
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
                  BrandManifestReveal(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: BigNumberField(
                            label: 'peso'.tr(),
                            unit: _config.weightUnit,
                            controller: _weightController,
                            hint: '0.0',
                            onChanged: (_) => _markQuoteStale(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: BigNumberField(
                            label: 'valor_fob'.tr(),
                            // FOB is declared in US dollars regardless of the
                            // currency the brand quotes in.
                            unit: r'US$',
                            unitLeading: true,
                            controller: _valueController,
                            onChanged: (_) => _markQuoteStale(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: BrandSpace.md),
                  BrandManifestReveal(
                    delay: brandManifestDelay(1),
                    child: _ProductAndAction(
                      products: _products,
                      selectedProduct: _selectedProduct,
                      loading: state is CalculadoraLoadingState,
                      onProductChanged: (product) {
                        setState(() {
                          _selectedProduct = product;
                          _validationMessage = null;
                          _quoteIsStale = true;
                        });
                      },
                      onCalculate: _calculate,
                    ),
                  ),
                  const SizedBox(height: BrandSpace.md),
                  if (_validationMessage != null) ...[
                    BrandManifestReveal(
                      key: ValueKey(_validationMessage),
                      child: _ValidationNotice(message: _validationMessage!),
                    ),
                    const SizedBox(height: BrandSpace.sm),
                  ],
                  BrandManifestReveal(
                    delay: brandManifestDelay(2),
                    child: _QuoteStage(
                      state: state,
                      config: _config,
                      quoteIsStale: _quoteIsStale,
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
    final weight = _parseDecimal(_weightController.text);
    final value = _parseDecimal(_valueController.text);
    if (weight == null ||
        value == null ||
        weight < _config.calculator.minimumWeight ||
        value < 0) {
      HapticFeedback.mediumImpact();
      setState(() {
        _validationMessage = 'valores_calculadora_invalidos'.tr(
          args: [
            _compactNumber(_config.calculator.minimumWeight),
            _config.weightUnit,
          ],
        );
        _quoteIsStale = true;
      });
      return;
    }
    setState(() {
      _validationMessage = null;
      _quoteIsStale = false;
    });
    _bloc.add(CalculateEvent(weight, value, _selectedProduct?.codigo ?? ''));
  }

  void _markQuoteStale() {
    if (_validationMessage != null || !_quoteIsStale) {
      setState(() {
        _validationMessage = null;
        _quoteIsStale = true;
      });
    }
  }
}

class _ProductAndAction extends StatelessWidget {
  const _ProductAndAction({
    required this.products,
    required this.selectedProduct,
    required this.loading,
    required this.onProductChanged,
    required this.onCalculate,
  });

  final List<Producto> products;
  final Producto? selectedProduct;
  final bool loading;
  final ValueChanged<Producto> onProductChanged;
  final VoidCallback onCalculate;

  @override
  Widget build(BuildContext context) {
    final selector = products.length > 1
        ? ProductSelector<Producto>(
            options: products,
            value: selectedProduct ?? products.first,
            labelFor: (product) => product.titulo,
            onChange: onProductChanged,
          )
        : null;
    if (selector == null) {
      return BrandPrimaryButton(
        label: 'calcular_envio'.tr(),
        onPressed: loading ? null : onCalculate,
      );
    }
    final action = BrandPrimaryButton(
      label: 'calcular_envio'.tr(),
      expand: false,
      onPressed: loading ? null : onCalculate,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        // Long product names and the English action need their own line on
        // compact phones. Wider layouts keep the reference's inline pairing.
        if (constraints.maxWidth < 390 || textScale > 1.3) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              selector,
              const SizedBox(height: BrandSpace.xs),
              BrandPrimaryButton(
                label: 'calcular_envio'.tr(),
                onPressed: loading ? null : onCalculate,
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: selector),
            const SizedBox(width: BrandSpace.xs),
            action,
          ],
        );
      },
    );
  }
}

class _ValidationNotice extends StatelessWidget {
  const _ValidationNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.accentWash(tokens.danger, 0.1),
          borderRadius: BorderRadius.circular(tokens.radiusSm),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BrandSpace.sm,
            vertical: 10,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, size: 18, color: tokens.danger),
              const SizedBox(width: BrandSpace.xs),
              Expanded(
                child: Text(
                  message,
                  style: tokens.body(
                    12,
                    weight: FontWeight.w600,
                    color: tokens.danger,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuoteStage extends StatelessWidget {
  const _QuoteStage({
    required this.state,
    required this.config,
    required this.quoteIsStale,
  });

  final CalculadoraState state;
  final BrandConfig config;
  final bool quoteIsStale;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.of(context).accessibleNavigation;
    final Widget content;
    if (state is CalculadoraLoadingState) {
      content = const BrandSkeleton(key: ValueKey('loading'), rows: 3);
    } else if (state is CalculadoraLoadedState && !quoteIsStale) {
      final result = state as CalculadoraLoadedState;
      content = _Result(
        key: ValueKey(
          'quote-${result.libras}-${result.valorFob}-${result.total}',
        ),
        state: result,
        config: config,
      );
    } else {
      content = const _CalculatorPrompt(key: ValueKey('prompt'));
    }

    return AnimatedSwitcher(
      duration:
          reducedMotion ? Duration.zero : const Duration(milliseconds: 420),
      reverseDuration:
          reducedMotion ? Duration.zero : const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutExpo,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final entrance = Tween<double>(begin: 0.86, end: 1).animate(animation);
        final offset = Tween<Offset>(
          begin: const Offset(0, 0.025),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: entrance,
          child: SlideTransition(position: offset, child: child),
        );
      },
      child: content,
    );
  }
}

class _CalculatorPrompt extends StatelessWidget {
  const _CalculatorPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BrandSpace.lg,
        vertical: BrandSpace.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BrandGlyphTile(
            asset: BrandIcons.calculator,
            size: 54,
            glyphSize: 28,
          ),
          const SizedBox(height: BrandSpace.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 290),
            child: Text(
              'tutor_calculadora'.tr(),
              textAlign: TextAlign.center,
              style: tokens.body(13, color: tokens.textMuted, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

/// Totals first, then the breakdown: the customer should not scroll to reach
/// the number they came for.
class _Result extends StatelessWidget {
  const _Result({super.key, required this.state, required this.config});

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
        Semantics(
          liveRegion: true,
          excludeSemantics: true,
          label:
              '${'total_flete'.tr()}: ${config.currency}${state.total.toStringAsFixed(2)}',
          child: Padding(
            padding: const EdgeInsets.only(bottom: BrandSpace.sm),
            child: Row(
              children: [
                const BrandGlyphTile(
                  asset: BrandIcons.calculator,
                  size: 42,
                  glyphSize: 22,
                ),
                const SizedBox(width: BrandSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('total_flete'.tr(), style: tokens.head(16)),
                      const SizedBox(height: 3),
                      Text(
                        '${_compactNumber(state.libras)} ${config.weightUnit}  ·  US\$${state.valorFob.toStringAsFixed(2)}',
                        style: tokens.body(11, color: tokens.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: BrandSpace.xs),
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tokens.accentWash(tokens.success, 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: tokens.success,
                  ),
                ),
              ],
            ),
          ),
        ),
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

double? _parseDecimal(String value) {
  final normalized = value.trim().replaceAll(',', '.');
  return double.tryParse(normalized);
}

String _compactNumber(double value) => value == value.truncateToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
