import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:icourier/services/model/banner.dart';
import 'package:icourier/services/model/empresa.dart';
import 'package:icourier/services/model/login_model.dart';
import '../../services/courier_service.dart';

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
        final empresa = await _courierService.getEmpresa();
        final banners = empresa.dominio.toUpperCase() == "BMCARGO" ? await _courierService.getBanners() : <BannerImage>[].toList();
        final userProfile = await _courierService.getUserProfile();
        final servicios = await _courierService.getServicios(event.ignoreCache);

        emit(ServiciosLoadedState(servicios, empresa, userProfile, banners));
      } catch (ex) {
        emit(ServiciosErrorState());
      }
    });
  }
}
