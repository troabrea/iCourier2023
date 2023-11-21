import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:empty_widget/empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/courier/courier_estado_cuenta.dart';
import 'package:icourier/courier/courier_facturados.dart';
import 'package:icourier/courier/courier_webview.dart';
import 'package:icourier/courier/crear_postalerta.dart';
import 'package:icourier/services/courier_service.dart';
import 'package:icourier/services/model/recepcion.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../apps/appinfo.dart';
import 'courier_prealertas_realizadas.dart';
import 'package:intl/intl.dart';
import '../../courier/bloc/dashboard_bloc.dart';
import '../../courier/courier_consulta_historica.dart';
import '../../courier/courier_recepciones.dart';
import '../../services/model/banner.dart';
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
  late ScrollController controller;
  final formatCurrency = NumberFormat.simpleCurrency(locale: "en-US");
  final appInfo = GetIt.I<AppInfo>();
  final showDisponiblesPopupMenu = true;

  DashboardBloc dashboardBloc = DashboardBloc(DashboardLoadingState());

  _CourierDashboardState() {
    GetIt.I<event.Event<CourierRefreshRequested>>().subscribe((args) {
      getDashboardBloc().add(const LoadApiEvent(true));
    });
  }

  DashboardBloc getDashboardBloc() {
    if (dashboardBloc.isClosed) {
      dashboardBloc = DashboardBloc(DashboardLoadingState());
    }
    return dashboardBloc;
  }

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
    GetIt.I<event.Event<UserPrealertaRequested>>().subscribe((args) {
      showPreAlertaSheet(context);
    });
    return BlocProvider(
      create: (context) => getDashboardBloc()..add(const LoadApiEvent(false)),
      child: SafeArea(
        child: BlocListener<DashboardBloc, DashboardState>(
          listener: (context, state) {
            if (state is DashboardFinishedState) {
              if (!state.withErrors) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                        Text('retiro_notificado'.tr())));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(state.errorMessage),
                  backgroundColor: Theme.of(context).errorColor,
                ));
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
                              if (appInfo.metricsPrefixKey != "TLS" && state.disponiblesCount > 0)
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
                                        icon: (showDisponiblesPopupMenu &&
                                                (state.empresa.hasDelivery ||
                                                    state.empresa
                                                        .hasNotifyModule ||
                                                    state.empresa
                                                        .hasPaymentsModule))
                                            ? PopupMenuButton<String>(
                                                itemBuilder: (context) {
                                                  return [
                                                    if (state.empresa
                                                        .hasNotifyModule)
                                                      PopupMenuItem(
                                                          value: 'retirar',
                                                          child: ListTile(
                                                            title: Text(
                                                                'notificar_retiro'.tr(),
                                                              style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Theme.of(context).colorScheme.onBackground),
                                                            ),
                                                            leading: const Icon(Icons
                                                                .meeting_room_outlined),
                                                          )),
                                                    if (state.empresa
                                                        .hasPaymentsModule && state.montoTotal > 0)
                                                      PopupMenuItem(
                                                          value: 'pagar',
                                                          child: ListTile(
                                                            title: Text('pagar'.tr(args: [formatCurrency
                                                                .format(state
                                                                .montoTotal)]),
                                                              style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Theme.of(context).colorScheme.onBackground),
                                                            ),
                                                            leading: const Icon(
                                                                Icons
                                                                    .credit_card_off_outlined),
                                                          )),
                                                    if (state
                                                        .empresa.hasDelivery)
                                                      const PopupMenuDivider(),
                                                    if (state
                                                        .empresa.hasDelivery)
                                                      PopupMenuItem(
                                                          value: 'domicilio',
                                                          child: ListTile(
                                                            title: Text(
                                                                'solicitar_domicilio'.tr(),
                                                              style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Theme.of(context).colorScheme.onBackground),
                                                            ),
                                                            leading: const Icon(Icons
                                                                .delivery_dining_outlined),
                                                          ))
                                                  ];
                                                },
                                                icon: const Icon(
                                                    Icons.more_vert_sharp),
                                                onSelected: (String value) {
                                                  if (value == 'retirar') {
                                                    BlocProvider.of<
                                                                DashboardBloc>(
                                                            context)
                                                        .add(
                                                            NotificarRetiroEvent(
                                                                context));
                                                  }
                                                  if (value == 'domicilio') {
                                                    BlocProvider.of<
                                                                DashboardBloc>(
                                                            context)
                                                        .add(SolicitarDomicilioEvent(
                                                            context,
                                                            state.recepciones
                                                                .where((element) =>
                                                                    element
                                                                        .disponible)
                                                                .toList()));
                                                  }
                                                  if (value == 'pagar') {
                                                    if(state.empresa.dominio.toUpperCase() == "CPS") {
                                                      doPayOnlineCPS();
                                                      return;
                                                    }
                                                    BlocProvider.of<
                                                                DashboardBloc>(
                                                            context)
                                                        .add(
                                                            OnlinePaymentRequestEvent(
                                                                context));
                                                  }
                                                },
                                              )
                                            : const Icon(
                                                IconData(0xe804,
                                                    fontFamily: 'iCourier'),
                                                size: 30,
                                              ),
                                        title: "disponibles".tr(),
                                        count: state.disponiblesCount)),
                              if (state.recepcionesCount > 0)
                                Container(
                                  margin: const EdgeInsets.only(
                                      top: 10.0, bottom: 10.0),
                                  child: InkWell(
                                      onTap: () {
                                        Navigator.of(context,
                                                rootNavigator: false)
                                            .push(MaterialPageRoute(
                                                builder: (context) =>
                                                    RecepcionesPage(
                                                        recepciones: state
                                                            .recepciones)));
                                      },
                                      child: SummaryBox(
                                          icon: const Icon(
                                            IconData(0xe812,
                                                fontFamily: 'iCourier'),
                                            size: 30,
                                          ),
                                          title: "recepciones".tr(),
                                          count: state.recepcionesCount)),
                                ),
                              if(appInfo.metricsPrefixKey == "TLS")
                                InkWell(
                                  onTap: () {
                                    Navigator.of(context, rootNavigator: false)
                                        .push(MaterialPageRoute(
                                        builder: (context) =>
                                            FacturadosPage(empresa: state.empresa,)));
                                  },
                                  child: SummaryBox(
                                      icon: const Icon(
                                        Icons.attach_money_sharp,
                                        size: 30,
                                      ),
                                      title: "facturas_pendientes".tr(),
                                      count: state.retenidosCount),
                                ),
                              if (state.retenidosCount > 0)
                                InkWell(
                                  onTap: () {
                                    Navigator.of(context, rootNavigator: false)
                                        .push(MaterialPageRoute(
                                            builder: (context) =>
                                                RecepcionesPage(
                                                    isRetenio: true,
                                                    titulo: "sin_factura".tr(),
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
                                      title: "sin_factura".tr(),
                                      count: state.retenidosCount),
                                ),
                              if (state.recepcionesCount == 0)
                                SizedBox(
                                  height: 180,
                                  width: 180,
                                  child: EmptyWidget(
                                    hideBackgroundAnimation: true,
                                    title: "no_paquetes".tr(),
                                    titleTextStyle: Theme.of(context).textTheme.titleLarge,
                                    subtitleTextStyle: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                              if (state.disponiblesCount == 0 || state.empresa.hasPointsModule)
                                const SizedBox(
                                  height: 10,
                                ),
                              if(state.empresa.hasPointsModule)
                                InkWell(
                                  onTap: () { launchUrl(Uri.parse(state.puntos.urlCanjeo)); } ,
                                  child: PointsSummaryBox(
                                      icon: const Icon(
                                        Icons.monetization_on_outlined,
                                        size: 25,
                                      ),
                                      title: state.empresa.dominio.toUpperCase() == "DOMEX" ? "domi_puntos_disponibles".tr() : "puntos_disponibles".tr(),
                                      count: state.puntos.balance.toInt()),
                                ),
                              if(state.empresa.hasPointsModule)
                                const SizedBox(height: 10,),
                              if(state.moreInfoText.isNotEmpty)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 5.0),
                                  child: Divider(thickness: 2),
                                ),
                              if(state.moreInfoText.isNotEmpty)
                                SizedBox(
                                  width: MediaQuery.of(context).size.width / 2,
                                  child: FilledButton(
                                      onPressed: () async {
                                         await launchUrl(Uri.parse(state.moreInfoUrl));
                                      },
                                      child: Column(
                                        children: [
                                          Text(state.moreInfoText, style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w600),),
                                          Text('suscribete'.tr(), style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Theme.of(context).colorScheme.onPrimary, decoration: TextDecoration.underline),),
                                        ],
                                      )),
                                ),
                              if(state.moreInfoText.isNotEmpty)
                                const Padding(
                                  padding: EdgeInsets.only(top: 5.0),
                                  child: Divider(thickness: 2,),
                                ),
                              if (state.empresa.hasDelivery &&
                                  state.disponiblesCount > 0)
                                Container(
                                  margin: const EdgeInsets.only(top: 10),
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                      icon: const Icon(
                                        Icons.motorcycle,
                                        size: 35,
                                      ),
                                      onPressed: () {
                                        BlocProvider.of<DashboardBloc>(context)
                                            .add(SolicitarDomicilioEvent(
                                                context,
                                                state.recepciones
                                                    .where((element) =>
                                                        element.disponible)
                                                    .toList()));
                                      },
                                      label: Text("solicitar_domicilio".tr())),
                                ),
                              if (state.disponiblesCount > 0)
                                const SizedBox(
                                  height: 15,
                                ),
                              if(state.empresa.dominio.toUpperCase() != "CARIBEPACK")
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton.icon(
                                        icon: const Icon(
                                          IconData(0xe817,
                                              fontFamily: 'iCourier'),
                                          size: 35,
                                        ),
                                        onPressed: () {
                                          showPreAlertaSheet(context);
                                        },
                                        label:
                                          Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                                              child: Text("crear_prealerta".tr()),
                                            )),
                                  ),
                                  const SizedBox(
                                    width: 20,
                                  ),
                                  Expanded(
                                    child: FilledButton.icon(
                                        icon: const Icon(
                                          IconData(0xe802,
                                              fontFamily: 'iCourier'),
                                          size: 35,
                                        ),
                                        onPressed: () {
                                          Navigator.of(context,
                                                  rootNavigator: false)
                                              .push(MaterialPageRoute(
                                                  builder: (context) =>
                                                      const PrealertasRealizadas()));
                                        },
                                        label: Padding(
                                          padding: const EdgeInsets.symmetric(vertical:4.0),
                                          child: Text(
                                              "ver_prealertas".tr()),
                                        )),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),

                              Row(
                                children: [
                                  Expanded(
                                      child: FilledButton.icon(
                                          icon: const Icon(
                                            IconData(0xe811,
                                                fontFamily: 'iCourier'),
                                            size: 35,
                                          ),
                                          onPressed: () {
                                            showTrackingSheet(context);
                                          },
                                          label:
                                               Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                                child: Text("rastrear_paquete".tr()),
                                              ))),
                                  const SizedBox(
                                    width: 20,
                                  ),
                                  Expanded(
                                    child: FilledButton.icon(
                                        icon: const Icon(
                                          IconData(0xe802,
                                              fontFamily: 'iCourier'),
                                          size: 35,
                                        ),
                                        onPressed: () {
                                          Navigator.of(context,
                                                  rootNavigator: false)
                                              .push(MaterialPageRoute(
                                                  builder: (context) =>
                                                      const ConsultaHistoricaPage()));
                                        },
                                        label:
                                             Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                                              child: Text("consulta_historica".tr()),
                                            )),
                                  ),
                                ],
                              ),
                              if(state.empresa.dominio.toUpperCase() == "CARIBEPACK")
                                const SizedBox(height: 25,),
                              if(state.empresa.dominio.toUpperCase() == "CARIBEPACK")
                                FilledButton.icon(
                                  onPressed: () { launchUrl(Uri.parse("https://caribetours.com.do/caribe-pack/tarifa-de-envios/")); } ,
                                  icon: const Icon(Icons.price_check),
                                  label: Text("nuestras_tarifas".tr()),
                                ),
                              if(state.empresa.dominio.toUpperCase() == "TAINO")
                                const SizedBox(height: 25,),
                              if(state.empresa.dominio.toUpperCase() == "TAINO")
                                Row(
                                children: [
                                  Expanded(
                                    child: FilledButton.icon(
                                        icon: const Icon(
                                          Icons.balance,
                                          size: 25,
                                        ),
                                        onPressed: () {
                                          Navigator.of(context,
                                              rootNavigator: false)
                                              .push(MaterialPageRoute(
                                              builder: (context) =>
                                              const EstadoDeCuenta()));
                                        },
                                        label:
                                        const Text("ver_estado_cuenta")),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
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

    Navigator.of(context,
        rootNavigator: false)
        .push( MaterialPageRoute( fullscreenDialog: true,
        builder: (context) =>
        const CrearPreAlertaPage()));

    //NavbarNotifier.hideBottomNavBar = true;

    // GetIt.I<event.Event<ToogleBarEvent>>().broadcast(ToogleBarEvent(false));
    // await showModalBottomSheet(
    //   context: context,
    //   isScrollControlled: true,
    //   shape: const RoundedRectangleBorder(
    //       borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    //   isDismissible: true,
    //   builder: (context) {
    //     return const CrearPreAlertaPage();
    //   },
    // );
    //
    // //NavbarNotifier.hideBottomNavBar = false;
    // GetIt.I<event.Event<ToogleBarEvent>>().broadcast(ToogleBarEvent(true));
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
      MaterialPageRoute(builder: (context) => CourierWebViewPage(htmlText: html, titulo: "realizar_pago")),
    );
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
  var trackingNumber = await cache.load('lasttrackednumber', '');

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
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    "error_favor_reintentar".tr())));
          }
        }
      }
    }
  }

  //NavbarNotifier.hideBottomNavBar = true;
  GetIt.I<event.Event<ToogleBarEvent>>().broadcast(ToogleBarEvent(false));
  final appInfo = GetIt.I<AppInfo>();

  if (appInfo.metricsPrefixKey == "CARIBEPACK") {
    await launchUrl(Uri.parse("https://caribepack-erp.iplus.app/fe/lg-es/ut/Estatus.aspx"));
    // await showModalBottomSheet(
    //     isScrollControlled: true,
    //     shape: const RoundedRectangleBorder(
    //         borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    //     context: context,
    //     builder: (builder) {
    //       return Container(
    //         height: 600,
    //         padding: const EdgeInsets.fromLTRB(0, 0, 0, 65),
    //         child: Column(mainAxisSize: MainAxisSize.min, children: [
    //           Container(
    //             decoration: ShapeDecoration(
    //                 color: Theme.of(context).appBarTheme.backgroundColor,
    //                 shape: const RoundedRectangleBorder(
    //                     borderRadius:
    //                         BorderRadius.vertical(top: Radius.circular(20)))),
    //             child: Column(
    //               children: [
    //                 Padding(
    //                   padding: const EdgeInsets.all(8.0),
    //                   child: Center(
    //                       child: Text("Rastreo de Paquete",
    //                           style: Theme.of(context)
    //                               .textTheme
    //                               .titleLarge
    //                               ?.copyWith(
    //                                   color: Theme.of(context)
    //                                       .appBarTheme
    //                                       .foregroundColor))),
    //                 ),
    //               ],
    //             ),
    //           ),
    //           // const SizedBox(
    //           //   height: 20,
    //           // ),
    //           const Expanded(child: WebView(initialUrl: "https://caribepack-erp.iplus.app/fe/lg-es/ut/Estatus.aspx",))
    //         ]),
    //       );
    //     });
    return;
  }

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
                          child: Text("rastreo_paquete".tr(),
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
                        contextMenuBuilder: (context, editableTextState) {
                          return AdaptiveTextSelectionToolbar.editableText(
                            editableTextState: editableTextState,
                          );
                        },
                        initialValue: trackingNumber,
                        decoration:  InputDecoration(
                          prefixIcon: const Icon(Icons.confirmation_number_outlined),
                          label: Text('numero_rastreo'.tr()),
                          helperText:
                              'numero_o_amazon_url'.tr(),
                        ),
                        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
                        validator: FormBuilderValidators.required(
                            errorText: 'requerido'.tr()),
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
          border: Border.all(color: Theme.of(context).dividerColor),
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
          if (count > 0)
            Transform.scale(
              scale: 0.8,
              child: CircleAvatar(
                  backgroundColor: Theme.of(context)
                      .appBarTheme
                      .backgroundColor!
                      .withOpacity(0.9),
                  foregroundColor:
                      Theme.of(context).appBarTheme.foregroundColor!,
                  child: Text(count.toString())),
            )
        ],
      ),
    );
  }
}

class PointsSummaryBox extends StatelessWidget {
  final Widget icon;
  final String title;
  final int count;

  const PointsSummaryBox(
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
          if (count > 0)
            Transform.scale(
              scale: 0.8,
              child: CircleAvatar(
                  backgroundColor: Theme.of(context)
                      .appBarTheme
                      .backgroundColor!
                      .withOpacity(0.9),
                  foregroundColor:
                  Theme.of(context).appBarTheme.foregroundColor!,
                  child: Text(count.toString(), style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),)),
            )
        ],
      ),
    );
  }
}