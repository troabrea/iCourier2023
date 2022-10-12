import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:app_bar_with_search_switch/app_bar_with_search_switch.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:map_launcher/map_launcher.dart' as map_launcher;
import 'package:permission_handler/permission_handler.dart';

import '../../services/app_events.dart';

import '../../services/courierService.dart';
import '../../sucursales/bloc/location_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/model/sucursal.dart';
import 'package:event/event.dart' as event;
import 'bloc/sucursales_bloc.dart';
import 'sucursalesappbar.dart';

class SucursalesPage extends StatefulWidget {
  const SucursalesPage({Key? key}) : super(key: key);

  @override
  State<SucursalesPage> createState() => _SucursalesPageState();
}

class _SucursalesPageState extends State<SucursalesPage> {
  late ScrollController controller;
  final sucursalesBloc = SucursalesBloc(GetIt.I<CourierService>());
  late List<Sucursal> sucursales;
  String searchText = "";
  var lastRefresh = DateTime.now();
  _SucursalesPageState() {
    GetIt.I<event.Event<SucursalesDataRefreshRequested>>().subscribe((args)  {
      if(DateTime.now().difference(lastRefresh).inMinutes >= 5) {
        sucursalesBloc.add(LoadApiEvent());
        lastRefresh = DateTime.now();
      }
    });
  }

  GoogleMapController? mapController;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  static CameraPosition get _kSantoDomingo => const CameraPosition(
        target: LatLng(18.4801205, -69.9819853),
        zoom: 10.0,
      );

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
        keepAppBarColors: false,
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
            title: const Text("Sucursales"),
            automaticallyImplyLeading: false,
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.whatsapp_rounded,
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
        create: (context) => sucursalesBloc..add(LoadApiEvent()),
        child: BlocBuilder<SucursalesBloc, SucursalesState>(
          builder: (context, state) {
            if (state is SucursalesLoadingState) {
              return const SafeArea(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if(state is SucursalesErrorState) {
              return SafeArea(child: Center(
                child: InkWell(onTap: () {
                  BlocProvider.of<SucursalesBloc>(context).add(LoadApiEvent(ignoreCache: true));
                }, child: Center(child: Text("Ha ocurrido un error haga clic para reintentar.", textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge,)),),
              ));
            }
            if (state is SucursalesLoadedState) {
              sucursales = state.sucursales;
              if(searchText.isNotEmpty) {
                sucursales = sucursales.where((element) => element.nombre.toLowerCase().contains(searchText.toLowerCase())).toList();
              }
              return SafeArea(
                child: Container(margin: const EdgeInsets.only(bottom: 65),
                  child: Column(
                      children: [
                    Container(
                      clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
                        height: MediaQuery.of(context).size.height * 0.30,
                        margin: const EdgeInsets.only(left: 12, right: 12, top: 12),
                        child: GoogleMap(
                            zoomControlsEnabled: true,
                            initialCameraPosition: _kSantoDomingo,
                            mapType: MapType.normal,
                            onMapCreated: _onMapCreated,
                            myLocationEnabled: true,
                            myLocationButtonEnabled: true,
                            markers: state.markers.values.toSet())),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: const BorderRadius.all(Radius.circular(10)),
                          border: Border.all(color: Theme.of(context).primaryColorDark),
                        ),
                        child: ListView.separated(
                            itemBuilder: (_, index) => InkWell(
                                onTap: () {
                                  mapController?.animateCamera(
                                      CameraUpdate.newLatLngZoom(
                                          LatLng(sucursales[index].latitud,
                                              sucursales[index].longitud),
                                          15));
                                },
                                child:
                                    sucursalTile(context, sucursales[index])),
                            controller: controller,
                            itemCount: sucursales.length,
                          separatorBuilder: (_,index) { return Divider(color: Theme.of(context).dividerColor, height: 1,); } ),
                      ),
                    )
                  ]),
                ),
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

  Widget sucursalTile(BuildContext context, Sucursal sucursal) {
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
                children: [
              if(sucursal.isFavorite)
                const Icon(Icons.star, size: 16, ),
              Expanded(
                child: Align(alignment: Alignment.centerLeft,
                  child: AutoSizeText( sucursal.nombre, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineMedium!.copyWith(fontWeight: FontWeight.w700)),
                ),
              ),
              IconButton( iconSize: 25,
                onPressed: () {
                  showSucursalOptions(context, sucursal);
                },
                icon: Icon(Icons.more_vert,color: Theme.of(context).iconTheme.color,),
              )
            ]),
            Text(sucursal.direccion),
            const SizedBox(height: 5,),
            AutoSizeText(sucursal.horario, maxLines: 2, minFontSize: 14, style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).textTheme.bodyMedium!.color!.withOpacity(0.7)), )
          ],
        ));
  }

  Future<void> showSucursalOptions(
      BuildContext context, Sucursal sucursal) async {


    Future<void> callSucursal(String phone) async {
      var _url = Uri.parse("tel://$phone");
      if (!await launchUrl(_url)) {
        throw 'Could not launch $_url';
      }
    }
    Future<void> chatWithSucursal(String phone) async {
      var _url = Uri.parse("whatsapp://send?phone=$phone");
      if (!await launchUrl(_url)) {
        throw 'Could not launch $_url';
      }
    }
    Future<void> mailSucursal(String email) async {
      var _url = Uri.parse("mailto:$email");
      if (!await launchUrl(_url)) {
        throw 'Could not launch $_url';
      }
    }

    final availableMaps = await map_launcher.MapLauncher.installedMaps;

    Future<void> navigateToSucursal() async {
      await availableMaps.first.showDirections(destination: map_launcher.Coords(sucursal.latitud, sucursal.longitud), destinationTitle: sucursal.nombre);
    }

    //NavbarNotifier.hideBottomNavBar = true;

    GetIt.I<event.Event<ToogleBarEvent>>().broadcast(ToogleBarEvent(false));

    await showModalBottomSheet(
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        context: context,
        builder: (builder) {
          return BlocProvider(create: (context) => LocationBloc()..add(LocationBlocCalculateDistanceEvent(sucursal.latitud, sucursal.longitud)),
            child: BlocBuilder<LocationBloc,LocationBlocState>(
              builder: (context, state) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: ShapeDecoration(color: Theme.of(context).appBarTheme.backgroundColor, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20)))),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(
                                child: AutoSizeText(sucursal.nombre,
                                    maxLines: 1,
                                    style:
                                    Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).appBarTheme.foregroundColor))),
                          ),
                          if(state is LocationBlocCalculatingDistinaceState)
                            Padding(
                                padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, right: 8.0),
                                child: Center(
                                    child: Text("Calculando distancia...",
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium?.copyWith(color: Theme.of(context).appBarTheme.foregroundColor)))),
                          if (state is LocationBlocDistanceAquiredState)
                            Padding(
                                padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, right: 8.0),
                                child: Center(
                                    child: Text(state.distance,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium?.copyWith(color: Theme.of(context).appBarTheme.foregroundColor))))
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.phone_rounded),
                          onPressed: () { callSucursal(sucursal.telefonoVentas); },
                          iconSize: 36,
                        ),
                        IconButton(
                          icon: const Icon(Icons.whatsapp_rounded),
                          onPressed: () { chatWithSucursal(sucursal.telefonoOficina); },
                          iconSize: 36,
                        ),
                        IconButton(
                          icon: const Icon(Icons.email_rounded),
                          onPressed: () { mailSucursal(sucursal.email); },
                          iconSize: 36,
                        ),
                        IconButton(
                          icon: const Icon(Icons.navigation_rounded),
                          onPressed: () { navigateToSucursal(); },
                          iconSize: 36,
                        ),
                      ],
                    ),
                    const Divider(
                      height: 5,
                      thickness: 1,
                    ),
                    Padding(
                      padding:
                      const EdgeInsets.only(top: 20, left: 20, right: 20),
                      child: Row(
                        children: [
                          const Icon(Icons.place, size: 14,),
                          const SizedBox(
                            width: 20,
                          ),
                          Expanded(
                            child: Text(sucursal.direccion),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding:
                      const EdgeInsets.only(top: 20, left: 20, right: 20),
                      child: Row(
                        children: [
                          const Icon(Icons.email, size: 14,),
                          const SizedBox(
                            width: 20,
                          ),
                          Expanded(
                            child: Text(sucursal.email),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding:
                      const EdgeInsets.only(top: 20, left: 20, right: 20),
                      child: Row(
                        children: [
                          const Icon(Icons.phone, size: 14,),
                          const SizedBox(
                            width: 20,
                          ),
                          Expanded(
                            child: Text(sucursal.telefonoVentas),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding:
                      const EdgeInsets.only(top: 20, left: 20, right: 20),
                      child: Row(
                        children: [
                          const Icon(Icons.whatsapp, size: 14,),
                          const SizedBox(
                            width: 20,
                          ),
                          Expanded(
                            child: Text(sucursal.telefonoOficina),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding:
                      const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 20),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule, size: 14,),
                          const SizedBox(
                            width: 20,
                          ),
                          Expanded(
                            child: Text(sucursal.horario),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 20,)
                  ],
                );
              },
            ),
          );
        });
    //NavbarNotifier.hideBottomNavBar = false;
    GetIt.I<event.Event<ToogleBarEvent>>().broadcast(ToogleBarEvent(true));

  }
}
