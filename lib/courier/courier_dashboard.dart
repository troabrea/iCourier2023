import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:empty_widget/empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:navbar_router/navbar_router.dart';
import 'package:sampleapi/courier/bloc/dashboard_bloc.dart';
import 'package:sampleapi/courier/courier_consulta_historica.dart';
import 'package:sampleapi/courier/courier_recepciones.dart';
import 'package:sampleapi/services/model/banner.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_events.dart';
import 'courier_disponibles.dart';
import 'package:flutter_cache/flutter_cache.dart' as cache;
import 'package:event/event.dart' as event;
import 'crear_prealerta.dart';

class CourierDashboard extends StatefulWidget {
  const CourierDashboard({Key? key}) : super(key: key);

  @override
  State<CourierDashboard> createState() => _CourierDashboardState();
}

class _CourierDashboardState extends State<CourierDashboard> {
  final ScrollController controller = ScrollController();
  final formatCurrency = NumberFormat.simpleCurrency(locale: "en-US");
  DashboardBloc dashboardBloc = DashboardBloc(DashboardLoadingState());

  _CourierDashboardState() {
    GetIt.I<event.Event<CourierRefreshRequested>>().subscribe((args) {
      getDashboardBloc().add(const LoadApiEvent(true));
    });
  }

  DashboardBloc getDashboardBloc()
  {
    if(dashboardBloc.isClosed) {
      dashboardBloc = DashboardBloc(DashboardLoadingState());
    }
    return dashboardBloc;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getDashboardBloc()..add(const LoadApiEvent(false)),
      child: SafeArea(
        child: BlocListener<DashboardBloc, DashboardState>(
  listener: (context, state) {
    if(state is DashboardFinishedState) {
      if(!state.withErrors) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Retiro de paquetes notificiado con éxito.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage), backgroundColor: Theme.of(context).errorColor,));
      }
    }
  },
  child: Container(
            margin: const EdgeInsets.only(bottom: 65),
            child: BlocBuilder<DashboardBloc, DashboardState>(
                builder: (context, state) {
              if (state is DashboardLoadingState) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              if (state is DashboardLoadedState) {
                return SingleChildScrollView(
                  controller: controller,
                  child: Column(
                    children: [
                      buildSlideShow(context, state.banners),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            if(state.recepcionesCount > 0)
                            InkWell(
                                onTap: () {
                                  Navigator.of(context,
                                          rootNavigator: false)
                                      .push(MaterialPageRoute(
                                          builder: (context) =>
                                              DisponiblesPage(
                                                empresa: state.empresa,
                                                disponibles: state
                                                    .recepciones
                                                    .where((e) =>
                                                        e.disponible ==
                                                        true)
                                                    .toList(),
                                                montoTotal:
                                                    state.montoTotal,
                                              )));
                                },
                                child: SummaryBox(
                                    icon: (state.empresa.hasDelivery || state.empresa.hasNotifyModule || state.empresa.hasPaymentsModule) ? PopupMenuButton<String>(itemBuilder: (context) {
                                          return [
                                            if(state.empresa.hasNotifyModule)
                                              const PopupMenuItem(value: 'retirar', child: Text('Notificar Retiro')),
                                            if(state.empresa.hasPaymentsModule)
                                              PopupMenuItem(value: 'pagar', child: Text('Pagar : ' + formatCurrency.format(state.montoTotal))),
                                            if(state.empresa.hasDelivery)
                                              const PopupMenuDivider(),
                                            if(state.empresa.hasDelivery)
                                              const PopupMenuItem(value: 'domicilio', child: Text('Solicitar Domicilio'))];
                                    }, icon: const Icon(Icons.more_vert_sharp), onSelected: (String value) {
                                      if(value == 'retirar') BlocProvider.of<DashboardBloc>(context).add(NotificarRetiroEvent());
                                      if(value == 'pagar') BlocProvider.of<DashboardBloc>(context).add(OnlinePaymentRequestEvent());
                                    }, ) : const Icon(
                                      IconData(0xe804,
                                          fontFamily: 'iCourier'),
                                      size: 30,
                                    ),
                                    title: "Disponibles",
                                    count: state.disponiblesCount)),
                            // if(state.disponiblesCount > 0)
                            //   Transform.translate( offset: const Offset(0,-1),
                            //     child: Container(
                            //       margin: const EdgeInsets.symmetric(horizontal: 15),
                            //       padding: const EdgeInsets.all(0),
                            //       decoration: BoxDecoration(
                            //           border: Border.all(color: Theme.of(context).primaryColorDark),
                            //           borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(6), bottomRight: Radius.circular(6))),
                            //       child: Row(
                            //         mainAxisAlignment: MainAxisAlignment.center,
                            //         children: [
                            //           ElevatedButton.icon(onPressed: () {BlocProvider.of<DashboardBloc>(context).add(NotificarRetiroEvent());}, style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),primary: Theme.of(context).appBarTheme.foregroundColor, onPrimary: Theme.of(context).appBarTheme.backgroundColor!.withAlpha(200)), icon: const Icon(Icons.meeting_room_outlined), label: const Text("Retirar")),
                            //           const SizedBox(width: 5),
                            //           ElevatedButton.icon(onPressed: () { BlocProvider.of<DashboardBloc>(context).add(OnlinePaymentRequestEvent()); }, style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),primary: Theme.of(context).appBarTheme.foregroundColor, onPrimary: Theme.of(context).appBarTheme.backgroundColor!.withAlpha(200)), icon: const Icon(Icons.payment), label: Text(formatCurrency.format(state.montoTotal))),
                            //         ],
                            //       ),
                            //     ),
                            //   ),
                            if(state.recepcionesCount > 0)
                            const SizedBox(
                              height: 10,
                            ),
                            if(state.recepcionesCount > 0)
                            InkWell(
                                onTap: () {
                                  Navigator.of(context,
                                          rootNavigator: false)
                                      .push(MaterialPageRoute(
                                          builder: (context) =>
                                              RecepcionesPage(
                                                  recepciones:
                                                      state.recepciones)));
                                },
                                child: SummaryBox(
                                    icon: const Icon(
                                      IconData(0xe812,
                                          fontFamily: 'iCourier'),
                                      size: 30,
                                    ),
                                    title: "Recepciones",
                                    count: state.recepcionesCount)),
                            if(state.recepcionesCount > 0)
                            const SizedBox(
                              height: 10,
                            ),
                            if(state.retenidosCount > 0)
                            InkWell(
                              onTap: () {
                                Navigator.of(context, rootNavigator: false)
                                    .push(MaterialPageRoute(
                                    builder: (context) =>
                                        RecepcionesPage(
                                            isRetenio: true,
                                            titulo: "Sin Factura",
                                            recepciones: state
                                                .recepciones
                                                .where((element) =>
                                            element.retenido ==
                                                true)
                                                .toList())));
                              },
                              child: SummaryBox(
                                  icon: const Icon(
                                    IconData(0xe817,
                                        fontFamily: 'iCourier'),
                                    size: 30,
                                  ),
                                  title: "Sin Factura",
                                  count: state.retenidosCount),
                            ),
                            if(state.recepcionesCount == 0)
                              SizedBox(height: 180,width: 180,
                                child: EmptyWidget(
                                  hideBackgroundAnimation: true,
                                  title: "No tiene paquetes!",
                                ),
                              ),
                            // InkWell(
                            //   onTap: () {
                            //
                            //   },
                            //   child: SummaryBox(
                            //       icon:  ElevatedButton(onPressed: () async {
                            //         await showPreAlertaSheet(context);
                            //       }, child: const Icon(Icons.add, size: 30,)
                            //       , style: ElevatedButton.styleFrom(
                            //             alignment: Alignment.topCenter,
                            //             padding: const EdgeInsets.all(5),
                            //             shape: RoundedRectangleBorder(
                            //                 borderRadius:
                            //                 BorderRadius.circular(6)),
                            //             primary: Theme.of(context)
                            //                 .appBarTheme
                            //                 .foregroundColor,
                            //             onPrimary: Theme.of(context)
                            //                 .appBarTheme
                            //                 .backgroundColor)),
                            //       title: "Pre-Alertas",
                            //       count: 0),
                            // ),
                            // const SizedBox(
                            //   height: 10,
                            // ),

                            const SizedBox(
                              height: 30,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                      icon: const Icon(
                                        IconData(0xe817,
                                            fontFamily: 'iCourier'),
                                        size: 35,
                                      ),
                                      style: ElevatedButton.styleFrom(
                                          alignment: Alignment.topCenter,
                                          padding:
                                          const EdgeInsets.symmetric(vertical: 10),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(
                                                  6)),
                                          primary: Theme.of(context)
                                              .appBarTheme
                                              .foregroundColor,
                                          onPrimary: Theme.of(context)
                                              .appBarTheme
                                              .backgroundColor),
                                      onPressed: () {
                                        showPreAlertaSheet(context);
                                      },
                                      label: const Text(
                                          "Realizar Pre-Alerta")),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                            Row(
                              children: [
                                Expanded(
                                    child: ElevatedButton.icon(
                                        icon: const Icon(
                                          IconData(0xe811,
                                              fontFamily: 'iCourier'),
                                          size: 35,
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          alignment: Alignment.topCenter,
                                            padding:
                                                const EdgeInsets.all(5),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        6)),
                                            primary: Theme.of(context)
                                                .appBarTheme
                                                .foregroundColor?.withOpacity(0.6),
                                            onPrimary: Theme.of(context)
                                                .appBarTheme
                                                .backgroundColor),
                                        onPressed: () {
                                          showTrackingSheet(context);
                                        },
                                        label: const Text(
                                            "Rastrear\nPaquete"))),
                                const SizedBox(
                                  width: 20,
                                ),
                                Expanded(
                                  child: ElevatedButton.icon(
                                      icon: const Icon(
                                        IconData(0xe802,
                                            fontFamily: 'iCourier'),
                                        size: 35,
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        alignment: Alignment.topCenter,
                                          padding: const EdgeInsets.all(5),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6)),
                                          primary: Theme.of(context)
                                              .appBarTheme
                                              .foregroundColor?.withOpacity(0.6),
                                          onPrimary: Theme.of(context)
                                              .appBarTheme
                                              .backgroundColor),
                                      onPressed: () {
                                        Navigator.of(context,
                                                rootNavigator: false)
                                            .push(MaterialPageRoute(
                                                builder: (context) =>
                                                    const ConsultaHistoricaPage()));
                                      },
                                      label:
                                          const Text("Consulta\nHistórica")),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              }
              return Container();
            })),
),
      ),
    );
  }

  Future<void> showPreAlertaSheet(BuildContext context) async {
    //NavbarNotifier.hideBottomNavBar = true;
    GetIt.I<event.Event<ToogleBarEvent>>().broadcast(ToogleBarEvent(false));
    await showModalBottomSheet(context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isDismissible: true,
      builder: (context) {
      return CrearPreAlertaPage();
    }, );

    //NavbarNotifier.hideBottomNavBar = false;
    GetIt.I<event.Event<ToogleBarEvent>>().broadcast(ToogleBarEvent(true));
  }
}

Widget buildSlideShow(BuildContext context, List<BannerImage> banners) {
  return ImageSlideshow(
    height: 145,
    indicatorRadius: 0,
    children: banners
        .map(
          (e) => CachedNetworkImage(
            imageUrl: e.url,
            imageBuilder: (context, imageProvider) => Container(
                decoration: BoxDecoration(
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.fill,
              ),
            )),
            progressIndicatorBuilder: (context, url, downloadProgress) =>
                Center(
                    child: CircularProgressIndicator(
                        value: downloadProgress.progress)),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        )
        .toList(),
    autoPlayInterval: 5000,
    isLoop: true,
  );
}

Future<void> showTrackingSheet(BuildContext context) async {
  final _formKey = GlobalKey<FormBuilderState>();
  var trackingNumber = await cache.load('lasttrackednumber','');

  Future<void> doShowTracking(String carrier) async {
    if (_formKey.currentState!.validate()) {
      trackingNumber =
          _formKey.currentState!.fields['tracking']!.value.toString();
      final Map<String, String> trackUrls = {
        "amazon": trackingNumber,
        "ups":
            "http://m.ups.com/mobile/track?trackingNumber=$trackingNumber&t=t",
        "fedex":
            "https://www.fedex.com/apps/fedextrack/?action=track&$trackingNumber={0}",
        "dhl":
            "https://mydhl.express.dhl/do/es/mobile.html#/tracking-results/$trackingNumber",
        "usps":
            "https://tools.usps.com/go/TrackConfirmAction.action?tRef=fullpage&tLc=1&text28777=&tLabels=$trackingNumber",
      };
      Navigator.of(context).pop();

      final _urlStr = trackUrls[carrier];

      if (_urlStr != null) {
        final _url = Uri.tryParse(_urlStr);
        if (_url != null) {
          if (await launchUrl(_url)) {
            await cache.write('lasttrackednumber', trackingNumber);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                    "Ha ocurrido un error intentando mostrar el rastreo.")));
          }
        }
      }
    }
  }
  //NavbarNotifier.hideBottomNavBar = true;
  GetIt.I<event.Event<ToogleBarEvent>>().broadcast(ToogleBarEvent(false));
  await showModalBottomSheet(
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      context: context,
      builder: (builder) {
        return Container(
          height: 600,
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 65),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: ShapeDecoration(
                    color: Theme.of(context).appBarTheme.backgroundColor,
                    shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)))),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                          child: Text("Rastreo de Paquete",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .appBarTheme
                                          .foregroundColor))),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: InkWell(
                      onTap: () {
                        doShowTracking('amazon');
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20.0),
                        child:
                            const Image(image: AssetImage('images/amazon.png')),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: InkWell(
                      onTap: () {
                        doShowTracking('dhl');
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20.0),
                        child: const Image(image: AssetImage('images/dhl.png')),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: InkWell(
                      onTap: () {
                        doShowTracking('fedex');
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20.0),
                        child:
                            const Image(image: AssetImage('images/fedex.png')),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: InkWell(
                      onTap: () {
                        doShowTracking('ups');
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20.0),
                        child: const Image(image: AssetImage('images/ups.png')),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: InkWell(
                      onTap: () {
                        doShowTracking('usps');
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20.0),
                        child:
                            const Image(image: AssetImage('images/usps.png')),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 30,
              ),
              SizedBox(
                height: 90,
                child: Container(
                    padding: const EdgeInsets.all(5),
                    child: FormBuilder(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      key: _formKey,
                      child: FormBuilderTextField(
                        name: 'tracking',
                        initialValue: trackingNumber,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.confirmation_number_outlined),
                          label: Text('Número de rastreo'),
                          helperText:
                              'Introduzca el número ó el url de amazon.',
                        ),
                        validator: FormBuilderValidators.required(
                            errorText: 'Requerido'),
                      ),
                    )),
              ),
              const SizedBox(
                height: 250,
              ),
            ],
          ),
        );
      });
  //NavbarNotifier.hideBottomNavBar = false;
  GetIt.I<event.Event<ToogleBarEvent>>().broadcast(ToogleBarEvent(true));
}

class SummaryBox extends StatelessWidget {
  final Widget icon;
  final String title;
  final int count;
  const SummaryBox(
      {Key? key, required this.icon, required this.title, required this.count})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).primaryColorDark),
          borderRadius: BorderRadius.circular(6)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          icon,
          Expanded(
              child: Center(
                  child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ))),
          if(count > 0)
          Transform.scale(scale: 0.8,
            child: CircleAvatar(backgroundColor:Theme.of(context).appBarTheme.backgroundColor!.withOpacity(0.9),foregroundColor: Theme.of(context).appBarTheme.foregroundColor!,
            child: Text(
              count.toString())
            ),
          )
        ],
      ),
    );
  }
}
