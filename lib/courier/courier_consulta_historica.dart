import 'package:empty_widget/empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:sampleapi/courier/bloc/historia_bloc.dart';
import 'package:sampleapi/courier/courier_historia_paquete.dart';
import 'package:sampleapi/courier/paquete_tile.dart';

class ConsultaHistoricaPage extends StatefulWidget {
  const ConsultaHistoricaPage({Key? key}) : super(key: key);

  @override
  State<ConsultaHistoricaPage> createState() => _ConsultaHistoricaPageState();
}

class _ConsultaHistoricaPageState extends State<ConsultaHistoricaPage> {
  final ScrollController controller = ScrollController();
  final _formKey = GlobalKey<FormBuilderState>();
  final historiaBloc = HistoriaBloc(HistoriaIdleState());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Consulta Histórica"),),
        body: BlocProvider(
          create: (context) => historiaBloc,
          child: BlocBuilder<HistoriaBloc, HistoriaState>(
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
                          buildEntryForm(context),
                          if (state is HistoriaLoadingState)
                            const Expanded(
                                child: Center(
                                  child: CircularProgressIndicator(),
                                )),
                          if(state is HistoriaIdleState)
                            Expanded(child: SizedBox( width: 250,height: 20, child: Center(child: EmptyWidget(
                                hideBackgroundAnimation: true,
                                title: "No hay resultados",
                                subTitle: "Especifique rango de fecha y ejecuta la busqueda.",
                            ),))),
                          if (state is HistoriaLoadedState)
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.only(top: 20),
                                child: ListView.builder(itemBuilder: (_, index) {
                                    return InkWell(onTap: () {
                                      Navigator.of(context,
                                          rootNavigator: false)
                                          .push(MaterialPageRoute(
                                          builder: (context) =>
                                           HistoricoPaquetePage(recepcion: state.recepciones[index])));
                                    }
                                        , child: PaqueteTile(recepcion: state.recepciones[index]));
                                }, itemCount: state.recepciones.length,),
                              ),
                            )
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

  Widget buildEntryForm(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SizedBox(
              width: MediaQuery.of(context).size.width * 0.4,
              child: buildDesdeFormField(context)),
          SizedBox(
              width: MediaQuery.of(context).size.width * 0.4,
              child: buildHastaFormField(context)),
          IconButton(
              onPressed: () {
                FocusScope.of(context).unfocus();
                if (_formKey.currentState!.saveAndValidate()) {
                  var desdeStr = _formKey.currentState?.fields['desde']?.value
                      .toString() ??
                      "";
                  desdeStr = desdeStr.replaceAll(',', '');

                  var hastaStr = _formKey.currentState?.fields['hasta']?.value
                      .toString() ??
                      "";
                  hastaStr = hastaStr.replaceAll(',', '');

                  var desde = DateTime.parse(desdeStr);
                  var hasta = DateTime.parse(hastaStr);
                  historiaBloc.add(LoadApiEvent(desde, hasta));
                }
              },
              icon: const Icon(Icons.search, size: 30,))
        ],
      ),
    );
  }

  FormBuilderDateTimePicker buildDesdeFormField(BuildContext context) {
    return FormBuilderDateTimePicker (
      name: 'desde',
      initialEntryMode: DatePickerEntryMode.calendar,
      format: DateFormat("dd-MMM-yyyy"),
      inputType: InputType.date,
      textAlign: TextAlign.center,
      initialValue: DateTime.now(),
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: 'Requerido'),
      ]),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.all(2),
        floatingLabelAlignment: FloatingLabelAlignment.center,
        labelText: 'Desde',
        floatingLabelStyle:
        TextStyle(color: Theme.of(context).primaryColorDark),
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).primaryColorDark),
            borderRadius: BorderRadius.circular(15)),
        focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).errorColor),
            borderRadius: BorderRadius.circular(15)),
        errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).errorColor),
            borderRadius: BorderRadius.circular(15)),
        enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).primaryColorDark),
            borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  FormBuilderDateTimePicker buildHastaFormField(BuildContext context) {
    return FormBuilderDateTimePicker (
      name: 'hasta',
      initialEntryMode: DatePickerEntryMode.calendar,
      format: DateFormat("dd-MMM-yyyy"),
      inputType: InputType.date,
      textAlign: TextAlign.center,
      initialValue: DateTime.now(),
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: 'Requerido'),
      ]),
      decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(2),
        floatingLabelAlignment: FloatingLabelAlignment.center,
        labelText: 'Hasta',
        floatingLabelStyle:
        TextStyle(color: Theme.of(context).primaryColorDark),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).primaryColorDark),
              borderRadius: BorderRadius.circular(15)),
          focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).errorColor),
              borderRadius: BorderRadius.circular(15)),
          errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).errorColor),
              borderRadius: BorderRadius.circular(15)),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).primaryColorDark),
              borderRadius: BorderRadius.circular(15)),
          ),
    );
  }
}
