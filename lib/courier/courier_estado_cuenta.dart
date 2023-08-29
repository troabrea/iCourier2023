
import 'package:auto_size_text/auto_size_text.dart';
import 'package:empty_widget/empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icourier/courier/bloc/estado_bloc.dart';
import 'package:icourier/services/model/estado_model.dart';
import 'package:intl/intl.dart';

import '../helpers/boxed_title_value.dart';

class EstadoDeCuenta extends StatefulWidget {
  const EstadoDeCuenta({Key? key}) : super(key: key);

  @override
  State<EstadoDeCuenta> createState() => _EstadoDeCuentaState();
}

class _EstadoDeCuentaState extends State<EstadoDeCuenta> {
  late ScrollController controller;
  final estadoBloc = EstadoBloc();
  final formatCurrency = NumberFormat.simpleCurrency(locale: "en-US");

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
        appBar: AppBar(
          title: const Text("Estado de Cuenta"),
          leading:
          BackButton(color: Theme.of(context).appBarTheme.iconTheme?.color),
        ),
        body: BlocProvider(
            create: (context) => estadoBloc..add(LoadEstadoEvent()),
            child: BlocBuilder<EstadoBloc, EstadoState>(
                builder: (context, state) {
                  if (state is EstadoLoadingState || state is EstadoInitial) {
                    return const SafeArea(
                        child: Center(
                          child: CircularProgressIndicator(),
                        ));
                  }
                  if (state is EstadoErrorState) {
                    return SafeArea(
                        child: Center(
                          child: InkWell(
                            onTap: () {
                              BlocProvider.of<EstadoBloc>(context)
                                  .add(LoadEstadoEvent());
                            },
                            child: Center(
                                child: Text(
                                  "Ha ocurrido un error haga clic para reintentar.",
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleLarge,
                                )),
                          ),
                        ));
                  }
                  if (state is EstadoEmptyState) {
                    return SafeArea(
                        child: Center(
                          child: InkWell(
                            onTap: () {
                              BlocProvider.of<EstadoBloc>(context)
                                  .add(LoadEstadoEvent());
                            },
                            child: Center(
                                child: EmptyWidget(
                                  hideBackgroundAnimation: true,
                                  title: "No hay resultados",
                                  subTitle: "No se encontraron registros en su estado de cuenta.",
                                  titleTextStyle: Theme.of(context).textTheme.bodyLarge,
                                  subtitleTextStyle: Theme.of(context).textTheme.bodySmall,
                                )),
                          ),
                        ));
                  }
                  if (state is EstadoLoadedState) {
                    return SafeArea(
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 65),
                          child: Column(
                            children: [
                              Expanded(child: _buildListView(context, state.estadoCuenta)),
                              _buildTotals(context, state.estadoCuenta)
                            ],
                          ),
                        ));
                  }
                  return Container();
                })));
  }

  Widget _buildListView(BuildContext context, List<EstadoResponse> estado) {
    return ListView.separated(
        itemBuilder: (_, index) => ListTile(
          leading: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(estado[index].diasVencidos.toString(),),
              Text('dias', style: Theme.of(context).textTheme.bodySmall,)
            ],
          ),
          title: AutoSizeText(estado[index].documento, maxLines: 1,style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),),
        subtitle: Text(estado[index].soloFecha(),),
          trailing: Text(formatCurrency.format(estado[index].balance), style: Theme.of(context).textTheme.titleMedium,),
        ),
        separatorBuilder: (_, idx) => const Divider(),
        controller: controller,
        itemCount: estado.length);
  }

  Widget _buildTotals(BuildContext context, List<EstadoResponse> estado)
  {
    double noVencido = 0;
    double vencido = 0;
    estado.forEach((element) {
      if(element.diasVencidos <= 30) {
        noVencido += element.balance;
      } else {
        vencido += element.balance;
      }
    });
    return Padding(padding: const EdgeInsets.all(8),
        child: SizedBox(height: 80,
            child: Row( mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                BoxedTitleAndValue(title: "No Vencido", value: formatCurrency.format(noVencido)),
                const SizedBox(width: 10,),
                BoxedTitleAndValue(title: "Vencido", value: formatCurrency.format(vencido)),
                const SizedBox(width: 10,),
                BoxedTitleAndValue(title: "Total", value: formatCurrency.format(vencido + noVencido)),
              ],)) );
  }


}