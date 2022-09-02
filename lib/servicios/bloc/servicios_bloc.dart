import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sampleapi/services/courierService.dart';

import '../../services/model/servicio.dart';

part 'servicios_event.dart';
part 'servicios_state.dart';

class ServiciosBloc extends Bloc<ServiciosEvent, ServiciosState> {
  final CourierService _courierService;
  // final ConnectivityService _connectivityService;

  ServiciosBloc(this._courierService) : super(ServiciosLoadingState()) {

    on<LoadApiEvent>((event, emit) async {
      try {
        emit(ServiciosLoadingState());
        final servicios = await _courierService.getServicios(event.ignoreCache);
        emit(ServiciosLoadedState(servicios));
      } catch (ex) {
        emit(ServiciosErrorState());
      }
    });
  }
}
