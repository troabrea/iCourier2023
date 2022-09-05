import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/courierService.dart';
import '../../services/model/sucursal.dart';

part 'sucursales_event.dart';
part 'sucursales_state.dart';

class SucursalesBloc extends Bloc<SucursalesEvent, SucursalesState> {
  final CourierService _courierService;

  SucursalesBloc(this._courierService) : super(SucursalesLoadingState()) {
    on<LoadApiEvent>((event, emit) async {
      try {
        emit(SucursalesLoadingState());
        final sucursales = await _courierService.getSucursales(
            event.ignoreCache);
        final Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
        for (var sucursal in sucursales) {
          final MarkerId markerId = MarkerId(sucursal.registroId);
          final Marker marker = Marker(
            markerId: markerId,
            position: LatLng(sucursal.latitud, sucursal.longitud),
            infoWindow: InfoWindow(
              title: sucursal.nombre,
              snippet: sucursal.direccion,
            ),
          );
          markers[markerId] = marker;
        }
        emit(SucursalesLoadedState(sucursales, markers));
      } catch(ex) {
        emit(SucursalesErrorState());
      }
    });
  }
}
