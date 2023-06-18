import 'package:app_bar_with_search_switch/app_bar_with_search_switch.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/courier_service.dart';
import '../appinfo.dart';
import '../services/model/servicio.dart';
import 'bloc/servicios_bloc.dart';

class ServiciosPage extends StatefulWidget {
  const ServiciosPage({Key? key}) : super(key: key);

  @override
  State<ServiciosPage> createState() => _ServiciosPageState();
}

class _ServiciosPageState extends State<ServiciosPage> {

  late ScrollController controller;
  final appInfo = GetIt.I<AppInfo>();
  List<Servicio> servicios = <Servicio>[].toList();
  String searchText = "";

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
      appBar: AppBarWithSearchSwitch(
        fieldHintText: 'Buscar',
        keepAppBarColors: true,
        onChanged: (text) {
          setState(() {
            searchText = text;
          });
        },
        // onSubmitted: (text) {
        //   searchText.value = text;
        // },
        appBarBuilder: (context) {
          return AppBar(
            title: const Text("Servicios"),
            automaticallyImplyLeading: false,
            leading: appInfo.metricsPrefixKey != "CARIBEPACK" ? BackButton( color: Theme.of(context).appBarTheme.iconTheme?.color) : null,
            actions: [
              IconButton(
                icon: FaIcon(FontAwesomeIcons.whatsapp,
                  color: Theme.of(context).appBarTheme.foregroundColor,
                ),
                onPressed: ()  {
                  chatWithSucursal();
                },
              ),
              IconButton(onPressed: AppBarWithSearchSwitch.of(context)?.startSearch, icon: Icon(Icons.search, color: Theme.of(context).appBarTheme.foregroundColor,)),
            ],
          );
        },
      ),
      body: BlocProvider(
        create: (context) => ServiciosBloc(
          GetIt.I<CourierService>(),
        )..add(const LoadApiEvent()),
        child: BlocBuilder<ServiciosBloc, ServiciosState>(
          builder: (context, state) {
            if (state is ServiciosLoadingState) {
              return const SafeArea(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (state is ServiciosLoadedState) {
              servicios = state.servicios;
              if(searchText.isNotEmpty) {
                servicios = servicios.where((element) => element.titulo.contains(searchText) || element.resumen.contains(searchText)).toList();
              }
              return SafeArea(
                child: Container(
                    padding: const EdgeInsets.fromLTRB(5,10,5,65),
                    child: ListView.builder(
                        itemBuilder: (_, index) => Card(
                            shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                            side: BorderSide(color: Theme.of(context).primaryColorDark)),
                            child: ExpansionTile(
                                  onExpansionChanged: ( (isExpanded)  => {
                                    setState( ()  => {
                                      servicios[index].isExpanded = isExpanded
                                    })
                                  }),
                                  expandedAlignment: Alignment.centerLeft,
                                  expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                                  title: Row(
                                    children: [
                                      // CircleAvatar(child: Text(state.servicios[index].orden.toStringAsFixed(0)),),
                                      // Text(state.servicios[index].orden.toStringAsFixed(0), style: Theme.of(context).textTheme.titleLarge,),
                                      // const SizedBox(width: 10,),
                                      Expanded(
                                        child: servicios[index].isExpanded ?
                                        AutoSizeText(
                                        servicios[index].titulo,
                                          maxLines: 5,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineMedium!,
                                        )
                                        :
                                        AutoSizeText(
                                          servicios[index].titulo,
                                          overflow: TextOverflow.ellipsis,
                                          minFontSize: 16,
                                          maxLines: 2,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium!,
                                        ),
                                      ),
                                    ],
                                  ),
                                  children: [
                                    Container(
                                        padding: const EdgeInsets.only(left: 5,right: 5,bottom: 5),
                                        child: Column(
                                          children: [
                                            const Divider(thickness: 2),
                                            Container( padding: const EdgeInsets.symmetric(horizontal: 10),
                                              child: Text(
                                                servicios[index].resumen,
                                                textAlign: TextAlign.justify,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium,
                                              ),
                                            ),
                                          ],
                                        )),
                                  ]),
                        ),
                        controller: controller,
                        itemCount: servicios.length)),
              );
            }
            return Container();
          },
        ),
      ),
    );
  }
  Future<void> chatWithSucursal() async {
    var userProfile = await GetIt.I<CourierService>().getUserProfile();
    var whatsApp = userProfile.whatsappSucursal; // (await GetIt.I<CourierService>().getEmpresa()).telefonoVentas;
    if (whatsApp.isNotEmpty) {
      var _url = Uri.parse("whatsapp://send?phone=$whatsApp");
      if (!await launchUrl(_url)) {
        throw 'Could not launch $_url';
      }
    }
  }
}
