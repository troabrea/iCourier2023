import 'package:easy_localization/easy_localization.dart';
import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/courier/bloc/facturados_bloc.dart';
import 'package:icourier/courier/courier_webview.dart';
import 'package:icourier/courier/factura_tile.dart';
import 'package:icourier/services/app_events.dart';
import 'package:icourier/services/model/login_model.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../courier/paquete_tile.dart';
import '../../services/model/empresa.dart';
import 'package:flutter_cache/flutter_cache.dart' as cache;
import '../apps/appinfo.dart';
import '../services/courier_service.dart';
import '../services/model/recepcion.dart';
import 'courier_historia_paquete.dart';

class FacturadosPage extends StatefulWidget {
  final Empresa empresa;

  FacturadosPage(
      {Key? key,
        required this.empresa})
      : super(key: key);

  @override
  State<FacturadosPage> createState() => _FacturadosPageState();
}

class _FacturadosPageState extends State<FacturadosPage> {
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

  FacturadosBloc disponibleBloc = FacturadosBloc(FacturadosInitialState());
  FacturadosBloc getFacturadosBloc() {
    if (disponibleBloc.isClosed) {
      disponibleBloc = FacturadosBloc(FacturadosInitialState());
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
          title: Text("facturas_pendientes".tr()),
          leading:
          BackButton(color: Theme.of(context).appBarTheme.iconTheme?.color),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh,
                color: Theme.of(context).appBarTheme.foregroundColor,
              ),
              onPressed: () async {
                getFacturadosBloc().add(FacturadosRefreshEvent());
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
          create: (context) => getFacturadosBloc()..add(FacturadosRefreshEvent()),
          child: BlocListener<FacturadosBloc, FacturadosState>(
            listener: (context, state) {
              if (state is FacturadosFinishedState) {
                if (!state.withErrors) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content:
                      Text('retiro_notificado'.tr())));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(state.errorMessage),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ));
                }
              }
            },
            child: BlocBuilder<FacturadosBloc, FacturadosState>(
              builder: (context, state) {
                if (state is FacturadosBusyState) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if(state is FacturadosReadyState) {
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
                                          'cantidad'.tr(),
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
                                          'total'.tr(),
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
                                                .format(state.montoTotal),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                color: Theme.of(context)
                                                    .appBarTheme
                                                    .foregroundColor))
                                      ],
                                    ),
                                    if (widget.empresa.hasDelivery)
                                      PopupMenuButton<String>(
                                        itemBuilder: (context) {
                                          return [
                                            if (widget
                                                .empresa.hasPaymentsModule)
                                              PopupMenuItem(
                                                  value: 'pagar',
                                                  child: ListTile(
                                                    title:
                                                    Text('realizar_pago'.tr()),
                                                    leading: const Icon(Icons
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
                                          if (value == 'pagar') {
                                            if(widget.empresa.dominio.toUpperCase() == "MARDOM") {
                                              doPayOnlineTLS(context, state);
                                              return;
                                            }
                                            BlocProvider.of<FacturadosBloc>(
                                                context)
                                                .add(FacturadosPagoEnLineaEvent(
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
                                      OutlinedButton.icon(
                                          onPressed: () {
                                            doPayOnlineTLS(context, state);
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
                                          label: Text("pagar_ahora".tr())),
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
                                    itemBuilder: (_, index) => Hero(
                                        transitionOnUserGestures: true,
                                        tag: state.disponibles[index],
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              for (var element in state.disponibles) {element.selected = false;}
                                              state.disponibles[index].selected = true;
                                            });

                                          },
                                          child: FacturaTile(
                                              recepcion: state
                                                  .disponibles[index]),
                                        )),
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

  void doPayOnlineTLS(BuildContext context, FacturadosReadyState state) async {
    final factura = state.disponibles.where((element) => element.selected).firstOrNull;

    if(factura == null) {
      showDialog(context: context, builder: (BuildContext context) => AlertDialog(
          actionsAlignment: MainAxisAlignment.spaceBetween,
          title: Text('alerta'.tr(),
              style: Theme.of(context).textTheme.titleLarge),
          content: Text("sin_factura_seleccionada".tr()),
      ));
      return;
    }

    final sessionId = (await cache.load('sessionId','')).toString();

    final url = "https://tls.com.do/en/factura/?id=${factura.recepcionID}&user=$sessionId";
    await launchUrl(Uri.parse(url));
  }

}
