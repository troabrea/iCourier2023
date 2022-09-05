import 'dart:async';
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:map_launcher/map_launcher.dart' as map_launcher;
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
  final ScrollController controller = ScrollController();
  final sucursalesBloc = SucursalesBloc(GetIt.I<CourierService>());

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SucursalesAppBar(),
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
              return SafeArea(
                child: Container(margin: const EdgeInsets.only(bottom: 65),
                  child: Column(children: [
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 0.30,
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
                                            LatLng(state.sucursales[index].latitud,
                                                state.sucursales[index].longitud),
                                            15));
                                  },
                                  child:
                                      sucursalTile(context, state.sucursales[index])),
                              controller: controller,
                              itemCount: state.sucursales.length,
                            separatorBuilder: (_,index) { return const Divider(); } ),
                        ))
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

  Widget sucursalTile(BuildContext context, Sucursal sucursal) {
    return Container(
        margin: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                  child: AutoSizeText(sucursal.nombre, maxLines: 1,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700))),
              IconButton(constraints: const BoxConstraints(maxHeight: 24),
                onPressed: () {
                  showSucursalOptions(context, sucursal);
                },
                icon: const Icon(Icons.pending),
              )
            ]),
            Text(sucursal.telefonoOficina),
            Text(sucursal.horario)
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
      var _url = Uri.parse("whatsapp://$phone");
      if (!await launchUrl(_url)) {
        throw 'Could not launch $_url';
      }
    }
    Future<void> mailSucursal(String email) async {
      var _url = Uri.parse("mailto://$email");
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
                          onPressed: () { callSucursal(sucursal.telefonoOficina); },
                          iconSize: 36,
                        ),
                        IconButton(
                          icon: const Icon(Icons.whatsapp_rounded),
                          onPressed: () { chatWithSucursal(sucursal.telefonoVentas); },
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
                          const Icon(Icons.phone, size: 14,),
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
                      const EdgeInsets.only(top: 20, left: 20, right: 20),
                      child: Row(
                        children: [
                          const Icon(Icons.whatsapp, size: 14,),
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
