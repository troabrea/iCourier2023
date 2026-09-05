import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/courier_service.dart';
import '../../services/model/sucursal.dart';

part 'sucursales_event.dart';
part 'sucursales_state.dart';

class SucursalesBloc extends Bloc<SucursalesEvent, SucursalesState> {
  final CourierService _courierService;

  SucursalesBloc(this._courierService) : super(SucursalesLoadingState()) {
    on<LoadApiEvent>((event, emit) async {
      try {
        emit(SucursalesLoadingState());
        // final appInfo = GetIt.I<AppInfo>();
        final userProfile = await _courierService.getUserProfile();
        final sucursales =
            await _courierService.getSucursales(event.ignoreCache);
        final Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
        for (var sucursal in sucursales) {
          sucursal.isFavorite = sucursal.codigo == userProfile.sucursal;
          final MarkerId markerId = MarkerId(sucursal.registroId);
          final Marker marker = Marker(
            markerId: markerId,
            icon: BitmapDescriptor.defaultMarker,
            position: LatLng(sucursal.latitud, sucursal.longitud),
            infoWindow: InfoWindow(
              title: sucursal.nombre,
              snippet: sucursal.direccion,
            ),
          );
          markers[markerId] = marker;
        }
        sucursales.sort((first, second) {
          if (first.isFavorite != second.isFavorite) {
            return first.isFavorite ? -1 : 1;
          }
          return first.orden.compareTo(second.orden);
        });
        //
        emit(SucursalesLoadedState(sucursales, markers));
      } catch (ex) {
        emit(SucursalesErrorState());
      }
    });
  }
}
