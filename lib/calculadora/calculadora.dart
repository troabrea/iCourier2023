import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_mask/easy_mask.dart';
import 'package:empty_widget/empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../calculadora/bloc/calculadora_bloc.dart';
import '../../services/courier_service.dart';
import 'package:intl/intl.dart';
import '../../services/model/calculadora_model.dart';
import '../apps/appinfo.dart';
import '../helpers/boxed_title_value.dart';
import '../services/model/producto.dart';
import 'calculadoraappbar.dart';

class CalculadoraPage extends StatefulWidget {
  const CalculadoraPage({Key? key}) : super(key: key);

  @override
  State<CalculadoraPage> createState() => _CalculadoraPageState();
}

class _CalculadoraPageState extends State<CalculadoraPage> {
  late ScrollController controller;
  final appInfo = GetIt.I<AppInfo>();
  final _formKey = GlobalKey<FormBuilderState>();
  List<Producto> productos = <Producto>[].toList();
  late Producto productoActual;
  final formatCurrency = NumberFormat.simpleCurrency(locale: "en-US");
  final numberCurrency = NumberFormat.decimalPattern("en-US");
  final calculadoraBloc = CalculadoraBloc(GetIt.I<CourierService>());

  @override
  void initState() {
    super.initState();
    controller = ScrollController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: const CalculadoraAppBar(),
        body: BlocProvider(
          create: (context) => calculadoraBloc..add(CalculatorPrepareEvent()),
          child: BlocBuilder<CalculadoraBloc, CalculadoraState>(
            builder: (context, state) {
              return SafeArea(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 65),
                  child: FormBuilder(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 20, 8, 0),
                      child: Column(
                        children: [
                          if (state is CalculadoraLoadingState)
                            const Expanded(
                                child: Center(
                              child: CircularProgressIndicator(),
                            )),
                          if(state is CalculadoraPreparedState)
                            buildEntryForm(context, state.productos, state.productoDefault),
                          if(state is CalculadoraLoadedState)
                            buildEntryForm(context, productos, productoActual),
                          if(state is CalculadoraPreparedState && state is! CalculadoraLoadedState)
                            Expanded(child: SizedBox( width: 250,height: 20, child: Center(child: EmptyWidget(
                              hideBackgroundAnimation: true,
                              title: "No hay resultados",
                              subTitle: "Especifique los valores y toque el boton calcular.",
                              titleTextStyle: Theme.of(context).textTheme.bodyLarge,
                              subtitleTextStyle: Theme.of(context).textTheme.bodySmall,
                            ),))),
                          if (state is CalculadoraLoadedState)
                            buildResults(context, state),
                          if (state is CalculadoraLoadedState)
                            const AutoSizeText("* Valores en RD\$ sujetos a cambios *", textAlign: TextAlign.center, maxLines: 2,),
                          if (state is CalculadoraLoadedState && state.valorFob >= 200)
                             const AutoSizeText("**Paquetes con valor comercial de US\$200.00 o mayor están sujetos al pago de impuestos y conllevan un cargo de gestión aduanal.", textAlign: TextAlign.center, maxLines: 2,),
                          if(state is CalculadoraLoadedState && state.email.isNotEmpty)
                            InkWell(onTap: () {
                              launchUrl(Uri.parse("mailto://${state.email}"));
                            }, child: AutoSizeText.rich(
                              TextSpan( text: "**Este es un estimado; Para una cotización exacta, escribir a: ",
                                children: [
                                  TextSpan(text: state.email, style: const TextStyle(decoration: TextDecoration.underline) )
                                ]
                               ), textAlign: TextAlign.center, maxLines: 2,)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ));
  }

  Widget buildResults(BuildContext context, CalculadoraLoadedState state) {
    return Expanded(
      child: Column(
        children: [
          Expanded(
              child: Container(
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      border:
                          Border.all(color: Theme.of(context).dividerColor),
                      borderRadius:
                          const BorderRadius.all(Radius.circular(10))),
                  child: buildListView(context, state.resultados))),
          buildTotals(context, state)
        ],
      ),
    );
  }

  Widget buildTotals(BuildContext context, CalculadoraLoadedState state)
  {
    return Padding(padding: const EdgeInsets.all(8),
    child: SizedBox(height: 80,
    child: Row( mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
      BoxedTitleAndValue(title: "Subtotal", value: formatCurrency.format(state.subtotal)),
      const SizedBox(width: 10,),
      BoxedTitleAndValue(title: "Impuestos", value: formatCurrency.format(state.impuestos)),
      const SizedBox(width: 10,),
      BoxedTitleAndValue(title: "Total", value: formatCurrency.format(state.total)),
    ],)) );
  }

  Widget buildEntryForm(BuildContext context, List<Producto> _productos, Producto _productoDefault) {
    if(productos.isEmpty) {
      productos = _productos;
      productoActual = _productoDefault;
    }
    return SizedBox(
      height: productos.length == 1 ? 75 : 120, // 110,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: productos.length == 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Column(
            children: [Row(children: [
              SizedBox(
                  width: MediaQuery.of(context).size.width * 0.4,
                  child: buildLibrasFormField(context)),
              const SizedBox(width: 3,),
              SizedBox(
                  width: MediaQuery.of(context).size.width * 0.4,
                  child: buildValorFormField(context)),
            ],),
              if(productos.length > 1)
                const SizedBox(height: 15,),
              if(productos.length > 1)
                SizedBox(  width: MediaQuery.of(context).size.width * 0.8, child: buildProductoField(context)),
            ],
          ),
          IconButton(iconSize: 30, color: Theme.of(context).colorScheme.primary,  alignment: Alignment.topCenter,
              onPressed: () {
                FocusScope.of(context).unfocus();
                if (_formKey.currentState!.saveAndValidate()) {
                  var librasStr = _formKey.currentState?.fields['libras']?.value
                          .toString() ??
                      "";
                  librasStr = librasStr.replaceAll(',', '');

                  var valorStr = _formKey.currentState?.fields['valor']?.value
                          .toString() ??
                      "";
                  valorStr = valorStr.replaceAll(',', '');

                  var libras = double.parse(librasStr);
                  var valor = double.parse(valorStr);

                  var codigoProducto = "";

                  if(productos.isNotEmpty && productos.length > 1) {
                    productoActual = _formKey.currentState?.fields['producto']?.value;
                    codigoProducto = productoActual.codigo;
                  }

                  calculadoraBloc.add(CalculateEvent(libras, valor, codigoProducto));
                }
              },
              icon: const Icon(Icons.calculate, size: 30,))
        ],
      ),
    );
  }

  FormBuilderTextField buildLibrasFormField(BuildContext context) {
    return FormBuilderTextField(
      name: 'libras',
      contextMenuBuilder: (context, editableTextState) {
        return AdaptiveTextSelectionToolbar.editableText(
          editableTextState: editableTextState,
        );
      },
      keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: true),
      textAlign: TextAlign.center,
      initialValue: appInfo.metricsPrefixKey == "BMCARGO" ? "1.00" : "1",
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
        // TextInputMask(
        //     mask: '9+,999.99',
        //     placeholder: appInfo.metricsPrefixKey == "BMCARGO" ? '' : '0',
        //     maxPlaceHolders: -1,
        //     reverse: true)
      ],
      autovalidateMode: AutovalidateMode.disabled,
      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: 'Requerido'),
        if(appInfo.metricsPrefixKey == "BMCARGO")
          FormBuilderValidators.min(0.20, errorText: 'Mayor de 0.20'),
        if(appInfo.metricsPrefixKey != "BMCARGO")
          FormBuilderValidators.min(1, errorText: 'Mayor de cero.'),
      ]),
      decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(2),
          labelText: 'Libras',
          floatingLabelAlignment: FloatingLabelAlignment.center,
          floatingLabelStyle:
              TextStyle(color: Theme.of(context).colorScheme.onSurface),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(10)),
          focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
              borderRadius: BorderRadius.circular(10)),
          errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
              borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(10)),
          prefixIcon: const Icon(Icons.balance_outlined),
          prefixIconColor: Theme.of(context).colorScheme.secondary),
    );
  }

  FormBuilderDropdown buildProductoField(BuildContext context) {
    return FormBuilderDropdown<Producto>(
      name: 'producto',
      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
      initialValue: productoActual,
      decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(2),
          labelText: 'Producto',
          floatingLabelAlignment: FloatingLabelAlignment.center,
          floatingLabelStyle:
          TextStyle(color: Theme.of(context).dividerColor),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(10)),
          focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
              borderRadius: BorderRadius.circular(10)),
          errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
              borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(10)),
          prefixIcon: const Icon(Icons.miscellaneous_services),
          prefixIconColor: Theme.of(context).colorScheme.secondary,
          hintText: 'Seleccione Producto'),
      items: productos
          .map((producto) => DropdownMenuItem(
        alignment: AlignmentDirectional.center,
        value: producto,
        child: Text(producto.titulo),
      ))
          .toList(),
    );
  }

  FormBuilderTextField buildValorFormField(BuildContext context) {
    return FormBuilderTextField(
      name: 'valor',
      keyboardType: const TextInputType.numberWithOptions(decimal: true,signed: false),
      textAlign: TextAlign.center,
      contextMenuBuilder: (context, editableTextState) {
        return AdaptiveTextSelectionToolbar.editableText(
          editableTextState: editableTextState,
        );
      },
      initialValue: appInfo.metricsPrefixKey == "BMCARGO" ? '0.20' : appInfo.metricsPrefixKey == "JETPACK" ? '0.00' : '100.00',
      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
        // TextInputMask(
        //     mask: '9+,999.99',
        //     placeholder: appInfo.metricsPrefixKey == "BMCARGO" ? '' : '0',
        //     maxPlaceHolders: 2,
        //     reverse: true)
      ], autovalidateMode: AutovalidateMode.disabled,
      validator: FormBuilderValidators.compose([
        if(appInfo.metricsPrefixKey != "JETPACK")
        FormBuilderValidators.required(errorText: "Requerido"),
        if(appInfo.metricsPrefixKey == "BMCARGO")
          FormBuilderValidators.min(0.20, errorText: 'Mayor de 0.20'),
        if(appInfo.metricsPrefixKey != "BMCARGO" && appInfo.metricsPrefixKey != "JETPACK")
          FormBuilderValidators.min(1, errorText: 'Mayor de cero.'),
      ]),
      decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(2),
          labelText: 'Valor FOB',
          floatingLabelAlignment: FloatingLabelAlignment.center,
          floatingLabelStyle:
              TextStyle(color: Theme.of(context).colorScheme.onSurface),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(10)),
          focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
              borderRadius: BorderRadius.circular(10)),
          errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
              borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(10)),
          prefixIcon: const Icon(Icons.attach_money_outlined),
          prefixIconColor: Theme.of(context).colorScheme.secondary),
    );
  }

  buildListView(BuildContext context, List<CalculadoraResponse> resultados) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: ListView.separated(
          itemBuilder: (_, index) => Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AutoSizeText.rich(
          TextSpan(text: resultados[index].productoNombre, children: [TextSpan(text: ' - ', style: Theme.of(context).textTheme.bodySmall ), TextSpan(text: resultados[index].unidadId)])
      ))]),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                          width: MediaQuery.of(context).size.width * 0.20,
                          child: AutoSizeText(
                            numberCurrency.format(resultados[index].cantidad),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            style: Theme.of(context).textTheme.titleSmall,
                          )),
                      
                      SizedBox(
                          width: MediaQuery.of(context).size.width * 0.20,
                          child: AutoSizeText(
                            formatCurrency.format(resultados[index].precio),
                            maxLines: 1,
                            textAlign: TextAlign.right,
                            style: Theme.of(context).textTheme.titleSmall,
                          )),
                      SizedBox(
                          width: MediaQuery.of(context).size.width * 0.20,
                          child: AutoSizeText(
                            formatCurrency.format(resultados[index].impuesto),
                            maxLines: 1,
                            textAlign: TextAlign.right,
                            style: Theme.of(context).textTheme.titleSmall,
                          )),
                      SizedBox(
                          width: MediaQuery.of(context).size.width * 0.20,
                          child: AutoSizeText(
                            formatCurrency.format(resultados[index].neto),
                            maxLines: 1,
                            textAlign: TextAlign.right,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).textTheme.titleMedium?.color),
                          )),
                    ],
                  )
                ],
              ),
          itemCount: resultados.length,
          separatorBuilder: (_, index) {
            return const Divider();
          }),
    );
  }

}

