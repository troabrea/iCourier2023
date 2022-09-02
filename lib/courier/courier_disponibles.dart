import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:sampleapi/courier/courierappbar.dart';
import 'package:sampleapi/courier/paquete_tile.dart';
import 'package:sampleapi/services/model/empresa.dart';

import '../services/courierService.dart';
import '../services/model/recepcion.dart';
import 'bloc/disponible_bloc.dart';
import 'courier_historia_paquete.dart';

class DisponiblesPage extends StatelessWidget {
  final List<Recepcion> disponibles;
  final Empresa empresa;
  final double montoTotal;
  final formatCurrency = NumberFormat.simpleCurrency(locale: "en-US");
  DisponiblesPage({Key? key, required this.disponibles, required this.montoTotal, required this.empresa})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Disponibles"),),
        body: BlocProvider(
  create: (context) => DisponibleBloc(),
  child: BlocListener<DisponibleBloc, DisponibleState>(
    listener: (context, state) {
      if(state is DisponibleFinishedState) {
        if(!state.withErrors) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Retiro de paquetes notificiado con éxito.')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage), backgroundColor: Theme.of(context).errorColor,));
        }
      }
    },child: BlocBuilder<DisponibleBloc, DisponibleState>(
  builder: (context, state) {
    if(state is DisponibleBusyState) {
      return const Center(child: CircularProgressIndicator(),);
    } else {
      return SafeArea(
            child: Container(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 65),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: ShapeDecoration(
                          color: Theme.of(context).appBarTheme.backgroundColor,
                          shape: const RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.all(Radius.circular(6)))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: AutoSizeText('Total: ' + formatCurrency.format(montoTotal), textAlign: TextAlign.start, maxLines: 1, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).appBarTheme.foregroundColor) )),
                          const SizedBox(width: 10,),
                          // ElevatedButton.icon(onPressed: () { BlocProvider.of<DisponibleBloc>(context).add(DisponibleNotificarRetiroEvent()); }, style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),primary: Theme.of(context).appBarTheme.foregroundColor, onPrimary: Theme.of(context).appBarTheme.backgroundColor), icon: const Icon(Icons.meeting_room_outlined), label: const Text("Retirar")),
                          // const SizedBox(width: 5),
                          // ElevatedButton.icon(onPressed: () { BlocProvider.of<DisponibleBloc>(context).add(DisponiblePagoEnLineaEvent()); }, style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),primary: Theme.of(context).appBarTheme.foregroundColor, onPrimary: Theme.of(context).appBarTheme.backgroundColor), icon: const Icon(Icons.payment), label: const Text("Pagar")),
                          PopupMenuButton<String>(itemBuilder: (context) {
                            return [
                              if(empresa.hasNotifyModule)
                                const PopupMenuItem(value: 'retirar', child: Text('Notificar Retiro')),
                              if(empresa.hasPaymentsModule)
                                const PopupMenuItem(value: 'pagar', child: Text('Realizar Pago')),
                              if(empresa.hasDelivery)
                                const PopupMenuDivider(),
                              if(empresa.hasDelivery)
                                const PopupMenuItem(value: 'domicilio', child: Text('Solicitar Domicilio'))];
                          },icon: Icon(Icons.more_vert_sharp, color: Theme.of(context).appBarTheme.foregroundColor,), color: Theme.of(context).scaffoldBackgroundColor, onSelected: (String value) {
                            if(value == 'retirar') BlocProvider.of<DisponibleBloc>(context).add(DisponibleNotificarRetiroEvent());
                            if(value == 'pagar') BlocProvider.of<DisponibleBloc>(context).add(DisponiblePagoEnLineaEvent());
                          }, )
                        ],
                      ),
                    ),
                    const SizedBox(height: 5,),
                    Expanded(
                      child: ListView.builder(
                          itemBuilder: (_, index) =>
                              InkWell(onTap: () {
                                Navigator.of(context, rootNavigator: false).push(MaterialPageRoute(
                                    builder: (context) =>
                                        HistoricoPaquetePage(recepcion: disponibles[index])));
                              }
                                  , child: PaqueteTile(recepcion: disponibles[index])),
                          itemCount: disponibles.length),
                    ),
                  ],
                )));
    }
  },
),
),
));
  }
}
