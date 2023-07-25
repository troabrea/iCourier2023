import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/courier/courier_webview.dart';
import 'package:icourier/services/app_events.dart';
import 'package:icourier/services/model/login_model.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../courier/paquete_tile.dart';
import '../../services/model/empresa.dart';

import '../apps/appinfo.dart';
import '../services/courier_service.dart';
import '../services/model/recepcion.dart';
import 'bloc/disponible_bloc.dart';
import 'courier_historia_paquete.dart';

class DisponiblesPage extends StatefulWidget {
  List<Recepcion> disponibles;
  final Empresa empresa;
  final double montoTotal;

  DisponiblesPage(
      {Key? key,
      required this.disponibles,
      required this.montoTotal,
      required this.empresa})
      : super(key: key);

  @override
  State<DisponiblesPage> createState() => _DisponiblesPageState();
}

class _DisponiblesPageState extends State<DisponiblesPage> {
  final formatCurrency = NumberFormat.simpleCurrency(locale: "en-US");
  bool _isInitialValue = true;
  late UserProfile userProfile;
  bool hasWhatsApp = false;
  bool isRefreshing = false;
  @override
  void initState() {
    super.initState();
    startAnimation();
    _configureWithProfile();
  }

  DisponibleBloc disponibleBloc = DisponibleBloc(DisponibleInitialState());
  DisponibleBloc getDisponibleBloc() {
    if (disponibleBloc.isClosed || disponibleBloc.state is DisponibleInitialState) {
      disponibleBloc = DisponibleBloc(DisponibleReadyState(disponibles: widget.disponibles));
    }
    return disponibleBloc;
  }

  Future<void> _configureWithProfile() async {
    userProfile = await GetIt.I<CourierService>().getUserProfile();
    setState(() {
      hasWhatsApp = userProfile.whatsappSucursal.isNotEmpty;
    });
  }

  Future<void> startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 50));
    setState(() {
      _isInitialValue = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
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
          title: const Text("Disponibles"),
          leading:
              BackButton(color: Theme.of(context).appBarTheme.iconTheme?.color),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh,
                color: Theme.of(context).appBarTheme.foregroundColor,
              ),
              onPressed: () async {
                getDisponibleBloc().add(DisponibleRefreshEvent());
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
        body: BlocProvider(
          create: (context) => getDisponibleBloc(),
          child: BlocListener<DisponibleBloc, DisponibleState>(
            listener: (context, state) {
              if (state is DisponibleFinishedState) {
                if (!state.withErrors) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content:
                          Text('Retiro de paquetes notificiado con éxito.')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(state.errorMessage),
                    backgroundColor: Theme.of(context).errorColor,
                  ));
                }
              }
            },
            child: BlocBuilder<DisponibleBloc, DisponibleState>(
              builder: (context, state) {
                if (state is DisponibleBusyState) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if(state is DisponibleReadyState) {
                  return SafeArea(
                      child: Container(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 65),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: ShapeDecoration(
                                    color: Theme.of(context)
                                        .appBarTheme
                                        .backgroundColor,
                                    shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(6)))),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      children: [
                                        Text(
                                          'Cantidad',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                  color: Theme.of(context)
                                                      .appBarTheme
                                                      .foregroundColor),
                                        ),
                                        Text(
                                            state.disponibles.length
                                                .toString(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                    color: Theme.of(context)
                                                        .appBarTheme
                                                        .foregroundColor))
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          'Total',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                  color: Theme.of(context)
                                                      .appBarTheme
                                                      .foregroundColor),
                                        ),
                                        Text(
                                            formatCurrency
                                                .format(widget.montoTotal),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                    color: Theme.of(context)
                                                        .appBarTheme
                                                        .foregroundColor))
                                      ],
                                    ),
                                    // Expanded(child: AutoSizeText('Total: ' + formatCurrency.format(montoTotal), textAlign: TextAlign.start, maxLines: 1, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).appBarTheme.foregroundColor) )),
                                    // const SizedBox(width: 10,),
                                    // FilledButton.icon(onPressed: () { BlocProvider.of<DisponibleBloc>(context).add(DisponibleNotificarRetiroEvent(context)); }, style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),primary: Theme.of(context).appBarTheme.foregroundColor, onPrimary: Theme.of(context).appBarTheme.backgroundColor), icon: const Icon(Icons.meeting_room_outlined), label: const Text("Retirar")),
                                    // const SizedBox(width: 5),
                                    // FilledButton.icon(onPressed: () { BlocProvider.of<DisponibleBloc>(context).add(DisponiblePagoEnLineaEvent(context)); }, style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),primary: Theme.of(context).appBarTheme.foregroundColor, onPrimary: Theme.of(context).appBarTheme.backgroundColor), icon: const Icon(Icons.payment), label: const Text("Pagar")),
                                    if (widget.empresa.hasDelivery)
                                      PopupMenuButton<String>(
                                        itemBuilder: (context) {
                                          return [
                                            const PopupMenuItem(
                                                value: 'domicilio',
                                                child: ListTile(
                                                  title: Text(
                                                      'Solicitar Domicilio'),
                                                  leading: Icon(Icons
                                                      .delivery_dining_outlined),
                                                )),
                                            const PopupMenuDivider(),
                                            if (widget.empresa.hasNotifyModule)
                                              const PopupMenuItem(
                                                  value: 'retirar',
                                                  child: ListTile(
                                                    title: Text(
                                                        'Notificar Retiro'),
                                                    leading: Icon(Icons
                                                        .meeting_room_rounded),
                                                  )),
                                            if (widget
                                                .empresa.hasPaymentsModule)
                                              const PopupMenuItem(
                                                  value: 'pagar',
                                                  child: ListTile(
                                                    title:
                                                        Text('Realizar Pago'),
                                                    leading: Icon(Icons
                                                        .credit_card_outlined),
                                                  )),
                                          ];
                                        },
                                        icon: Icon(
                                          Icons.more_vert_sharp,
                                          color: Theme.of(context)
                                              .appBarTheme
                                              .foregroundColor,
                                        ),
                                        color: Theme.of(context)
                                            .scaffoldBackgroundColor,
                                        onSelected: (String value) {
                                          if (value == 'retirar') {
                                            BlocProvider.of<DisponibleBloc>(
                                                    context)
                                                .add(
                                                    DisponibleNotificarRetiroEvent(
                                                        context));
                                          }
                                          if(value == 'domicilio') {
                                            BlocProvider.of<DisponibleBloc>(
                                                context)
                                                .add(DisponibleDomicilioEvent(
                                                context,state.disponibles ));
                                          }
                                          if (value == 'pagar') {
                                            if(widget.empresa.dominio.toUpperCase() == "CPS") {
                                              doPayOnlineCPS();
                                              return;
                                            }
                                            BlocProvider.of<DisponibleBloc>(
                                                    context)
                                                .add(DisponiblePagoEnLineaEvent(
                                                    context));
                                          }
                                        },
                                      )
                                  ],
                                ),
                              ),
                              //const SizedBox(height: 5,),
                              AnimatedContainer(
                                height: _isInitialValue ? 0 : 50,
                                duration: const Duration(milliseconds: 250),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                padding: const EdgeInsets.all(0),
                                decoration: BoxDecoration(
                                    border: Border(top: BorderSide(color: Theme.of(context).dividerColor, width: 0), left: BorderSide(color: Theme.of(context).dividerColor),
                                        bottom: BorderSide(color: Theme.of(context).dividerColor),
                                        right: BorderSide(color: Theme.of(context).dividerColor)),
                                    borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(6),
                                        bottomRight: Radius.circular(6))),
                                //borderRadius: const BorderRadius.all(Radius.circular(6))),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 15,
                                    ),
                                    if (widget.empresa.hasNotifyModule)
                                      OutlinedButton.icon(
                                          onPressed: () {
                                            BlocProvider.of<DisponibleBloc>(
                                                    context)
                                                .add(
                                                    DisponibleNotificarRetiroEvent(
                                                        context));
                                          },
                                          style: FilledButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6)),
                                              backgroundColor: Theme.of(context)
                                                  .appBarTheme
                                                  .foregroundColor,
                                              foregroundColor: Theme.of(context)
                                                  .appBarTheme
                                                  .backgroundColor!
                                                  .withAlpha(250)),
                                          icon: const Icon(
                                              Icons.meeting_room_outlined),
                                          label: const Text("Retirar")),
                                    const Spacer(),
                                    if (widget.empresa.hasPaymentsModule && widget.montoTotal > 0)
                                      OutlinedButton.icon(
                                          onPressed: () {
                                            BlocProvider.of<DisponibleBloc>(
                                                    context)
                                                .add(DisponiblePagoEnLineaEvent(
                                                    context));
                                          },
                                          style: FilledButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6)),
                                              backgroundColor: Theme.of(context)
                                                  .appBarTheme
                                                  .foregroundColor,
                                              foregroundColor: Theme.of(context)
                                                  .appBarTheme
                                                  .backgroundColor!
                                                  .withAlpha(250)),
                                          icon: const Icon(Icons.payment),
                                          label: const Text("Pagar")),
                                    const SizedBox(
                                      width: 15,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              Expanded(
                                child: ListView.builder(
                                    itemBuilder: (_, index) => InkWell(
                                        onTap: () {
                                          Navigator.of(context,
                                                  rootNavigator: false)
                                              .push(MaterialPageRoute(
                                                  builder: (context) =>
                                                      HistoricoPaquetePage(
                                                          recepcion: widget
                                                                  .disponibles[
                                                              index])));
                                        },
                                        child: Hero(
                                            transitionOnUserGestures: true,
                                            tag: state.disponibles[index],
                                            child: PaqueteTile(
                                                recepcion: state
                                                    .disponibles[index]))),
                                    itemCount: state.disponibles.length),
                              ),
                            ],
                          )));
                } else {
                  return Container();
                }
              },
            ),
          ),
        ));
  }

  void doPayOnlineCPS() async {
    final map = await GetIt.I<CourierService>().getPaymentUrl();
    final actionUrl = map['ActionURL'] ?? "";
    final userId = map['UsuarioID'] ?? "";
    final userPwd = map['UsuarioPW'] ?? "";
    final urlId = map['UrlID'] ?? "";
    final html = '<html><head></head><body onload="document.ipluspostpage.submit()"><form name="ipluspostpage" method="POST" action="$actionUrl" accept-charset="utf-8"><input name="UsuarioID" type="hidden" value="$userId"><input name="UsuarioPW" type="hidden" value="$userPwd"><input name="UrlID" type="hidden" value="$urlId"></form></body></html>';
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CourierWebViewPage(htmlText: html, titulo: "Realizar Pago")),
    );
  }

}
