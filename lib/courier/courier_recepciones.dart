import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../courier/paquete_tile.dart';
import '../services/app_events.dart';
import '../services/model/recepcion.dart';
import 'courier_historia_paquete.dart';
import 'crear_postalerta.dart';
import 'package:event/event.dart' as event;

class RecepcionesPage extends StatelessWidget {
  final List<Recepcion> recepciones;
  late String titulo;
  late bool isRetenio;
  RecepcionesPage({Key? key, required this.recepciones, this.titulo = "Recepciones", this.isRetenio = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(titulo),),
        body: SafeArea(
            child: Container(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 65),
                child: ListView.builder(
                    itemBuilder: (_, index) =>
                        InkWell(onTap: () {
                          var recepcion = recepciones[index];
                          if(this.isRetenio) {
                            showPostAlertaSheet(context, recepcion);
                          } else {
                            Navigator.of(context, rootNavigator: false).push(MaterialPageRoute(
                                builder: (context) =>
                                    HistoricoPaquetePage(recepcion: recepcion)));
                          }
                        }, child: Hero(transitionOnUserGestures: true, tag: recepciones[index], child: PaqueteTile(recepcion: recepciones[index]))),

                    itemCount: this.recepciones.length))));
  }

  Future<void> showPostAlertaSheet(BuildContext context, Recepcion recepcion) async {
    //NavbarNotifier.hideBottomNavBar = true;
    GetIt.I<event.Event<ToogleBarEvent>>().broadcast(ToogleBarEvent(false));
    await showModalBottomSheet(context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isDismissible: true,
      builder: (context) {
        return CrearPostAlertaPage(recepcion: recepcion);
      }, );

    //NavbarNotifier.hideBottomNavBar = false;
    GetIt.I<event.Event<ToogleBarEvent>>().broadcast(ToogleBarEvent(true));
  }
}
