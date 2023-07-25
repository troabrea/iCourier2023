import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:grouped_list/sliver_grouped_list.dart';
import 'package:icourier/courier/bloc/dashboard_bloc.dart';
import 'package:icourier/courier/bloc/dashboard_bloc.dart';
import 'package:icourier/services/model/login_model.dart';
import '../apps/appinfo.dart';
import '../services/courier_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../courier/paquete_tile.dart';
import '../services/app_events.dart';
import '../services/model/recepcion.dart';
import 'courier_historia_paquete.dart';
import 'crear_postalerta.dart';
import 'package:event/event.dart' as event;

class RecepcionesPage extends StatefulWidget {
  List<Recepcion> recepciones;
  final String titulo;
  final bool isRetenio;

  RecepcionesPage(
      {Key? key,
      required this.recepciones,
      this.titulo = "Recepciones",
      this.isRetenio = false})
      : super(key: key);

  @override
  State<RecepcionesPage> createState() => _RecepcionesPageState();
}

class _RecepcionesPageState extends State<RecepcionesPage> {
  late UserProfile userProfile;
  bool hasWhatsApp = false;
  bool isRefreshing = false;
  @override
  void initState() {
    super.initState();
    _configureWithProfile();
  }

  Future<void> _configureWithProfile() async {
    userProfile = await GetIt.I<CourierService>().getUserProfile();
    setState(() {
      hasWhatsApp = userProfile.whatsappSucursal.isNotEmpty;
    });
  }

  Future<void> chatWithSucursal() async {
    var whatsApp = userProfile
        .whatsappSucursal; // (await GetIt.I<CourierService>().getEmpresa()).telefonoVentas;
    if (whatsApp.isNotEmpty) {
      var _url = Uri.parse("whatsapp://send?phone=$whatsApp");
      if (!await launchUrl(_url)) {
        throw 'Could not launch $_url';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.titulo),
          leading:
              BackButton(color: Theme.of(context).appBarTheme.iconTheme?.color),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh,
                color: Theme.of(context).appBarTheme.foregroundColor,
              ),
              onPressed: () async {
                GetIt.I<Event<CourierRefreshRequested>>()
                    .broadcast(CourierRefreshRequested());
                try
                {
                  setState(() {
                    isRefreshing = true;
                  });

                  widget.recepciones = await GetIt.I<CourierService>().getRecepciones(true);

                } finally {
                  setState(() {
                    isRefreshing = false;
                  });
                }



              },
            ),
            if(hasWhatsApp)
            IconButton(
              icon: FaIcon(FontAwesomeIcons.whatsapp,
                color: Theme.of(context).appBarTheme.foregroundColor,
              ),
              onPressed: () {
                chatWithSucursal();
              },
            ),
          ],
        ),
        body: SafeArea(
            child: Container(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 65),
                child: isRefreshing ? const Center(child: CircularProgressIndicator()) : CustomScrollView(slivers: [
                  SliverGroupedListView<Recepcion, String>(
                    elements: widget.recepciones,
                    groupBy: (element) => element.estatus,
                    groupSeparatorBuilder: (String value) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        value,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium!
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    itemBuilder: (context, Recepcion recepcion) => InkWell(
                        onTap: () {
                          if (widget.isRetenio) {
                            showPostAlertaSheet(context, recepcion);
                          } else {
                            Navigator.of(context, rootNavigator: false).push(
                                MaterialPageRoute(
                                    builder: (context) => HistoricoPaquetePage(
                                        recepcion: recepcion)));
                          }
                        },
                        child: Hero(
                            transitionOnUserGestures: true,
                            tag: recepcion,
                            child: PaqueteTile(recepcion: recepcion))),
                  ),
                ])
            )
        )
    );
    // child: ListView.builder(
    //     itemBuilder: (_, index) =>
    //         InkWell(onTap: () {
    //           var recepcion = recepciones[index];
    //           if(this.isRetenio) {
    //             showPostAlertaSheet(context, recepcion);
    //           } else {
    //             Navigator.of(context, rootNavigator: false).push(MaterialPageRoute(
    //                 builder: (context) =>
    //                     HistoricoPaquetePage(recepcion: recepcion)));
    //           }
    //         }, child: Hero(transitionOnUserGestures: true, tag: recepciones[index], child: PaqueteTile(recepcion: recepciones[index]))),
    //
    //     itemCount: this.recepciones.length))));
  }

  Future<void> showPostAlertaSheet(
      BuildContext context, Recepcion recepcion) async {

    Navigator.of(context,
        rootNavigator: false)
        .push(MaterialPageRoute(fullscreenDialog: true,
        builder: (context) =>
         CrearPostAlertaPage(recepcion: recepcion)));

    //NavbarNotifier.hideBottomNavBar = true;
    // GetIt.I<event.Event<ToogleBarEvent>>().broadcast(ToogleBarEvent(false));
    // await showModalBottomSheet(
    //   context: context,
    //   isScrollControlled: true,
    //   shape: const RoundedRectangleBorder(
    //       borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    //   isDismissible: true,
    //   builder: (context) {
    //     return CrearPostAlertaPage(recepcion: recepcion);
    //   },
    // );
    //
    // //NavbarNotifier.hideBottomNavBar = false;
    // GetIt.I<event.Event<ToogleBarEvent>>().broadcast(ToogleBarEvent(true));
  }
}
