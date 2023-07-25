import 'package:app_bar_with_search_switch/app_bar_with_search_switch.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/helpers/social_media_links.dart';
import 'package:icourier/services/model/banner.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/courier_service.dart';
import '../apps/appinfo.dart';
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
        fieldHintText: 'buscar',
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
            centerTitle: true,
            automaticallyImplyLeading: false,
            leading: appInfo.metricsPrefixKey != "CARIBEPACK" && appInfo.metricsPrefixKey != "BMCARGO" ? BackButton( color: Theme.of(context).appBarTheme.iconTheme?.color) : null,
            actions: [
              IconButton(
                icon: FaIcon(FontAwesomeIcons.whatsapp,
                  color: Theme.of(context).appBarTheme.foregroundColor,
                ),
                onPressed: ()  {
                  chatWithSucursal();
                },
              ),
              IconButton(onPressed: AppBarWithSearchSwitch.of(context)?.startSearch,
                  icon: Icon(Icons.search,
                    color: Theme.of(context).appBarTheme.foregroundColor,)),
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(5,10,5,65),
                  child: Column(
                    children: [
                      if(state.banners.isNotEmpty)
                        buildSlideShow(context, state.banners),
                      if(appInfo.metricsPrefixKey == "BMCARGO")
                      SizedBox(height: 50,
                          child: SocialMediaLinks(empresa: state.empresa, userProfile: state.userProfile,)),
                      const SizedBox(height: 10,),
                      Expanded(
                        child: ListView.builder(
                            itemBuilder: (_, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: ExpansionTile(
                                iconColor: Theme.of(context).colorScheme.primary,
                                  collapsedTextColor: Theme.of(context).colorScheme.onPrimary,
                                  collapsedShape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      side: BorderSide(color: Theme.of(context).dividerColor)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      side: BorderSide(color: Theme.of(context).dividerColor)),
                                maintainState: true,
                                    initiallyExpanded: false,
                                    onExpansionChanged: ( (isExpanded)  => {
                                      setState( ()  => servicios[index].isExpanded = isExpanded
                                      )
                                    }),
                                    expandedAlignment: Alignment.centerLeft,
                                    expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                                    title: AutoSizeText(
                                      servicios[index].titulo,
                                      overflow: TextOverflow.ellipsis,
                                      minFontSize: 10,
                                      maxFontSize: 18,
                                      maxLines: 2,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge!.copyWith(fontWeight: servicios[index].isExpanded ? FontWeight.bold : FontWeight.normal,
                                          color: servicios[index].isExpanded ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onBackground
                                      ),
                                    ),
                                    children: [
                                      Container(
                                          padding: const EdgeInsets.only(left: 5,right: 5,bottom: 5),
                                          child: Column(
                                            children: [
                                              // const Divider(thickness: 1),
                                              Container( padding: const EdgeInsets.symmetric(horizontal: 10),
                                                child: Text(
                                                  servicios[index].resumen,
                                                  textAlign: TextAlign.justify,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium,
                                                ),
                                              ),
                                            ],
                                          )),
                                    ]),
                            ),
                            controller: controller,
                            itemCount: servicios.length),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Container();
          },
        ),
      ),
    );
  }

  Widget buildSlideShow(BuildContext context, List<BannerImage> banners)
  {
    return ImageSlideshow(height: 145, indicatorRadius: 0, children: banners.map((e) =>
        CachedNetworkImage(
          imageUrl: e.url,
          imageBuilder: (context, imageProvider) => Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: imageProvider,
                  fit: MediaQuery.of(context).size.width < 800 ? BoxFit.fill : BoxFit.cover,
                ),
              )),
          progressIndicatorBuilder: (context, url, downloadProgress) =>
              Center(child: CircularProgressIndicator(value: downloadProgress.progress)),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),).toList(), autoPlayInterval: 8500, isLoop: true,);
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
