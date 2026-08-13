import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../services/courier_service.dart';
import '../../services/model/banner.dart';
import '../../services/model/empresa.dart';
import '../../services/model/login_model.dart';
import '../../services/model/servicio.dart';

part 'servicios_event.dart';
part 'servicios_state.dart';

class ServiciosBloc extends Bloc<ServiciosEvent, ServiciosState> {
  final CourierService _courierService;
  final bool _loadBanners;
  // final ConnectivityService _connectivityService;

  ServiciosBloc(this._courierService, {bool loadBanners = false})
      : _loadBanners = loadBanners,
        super(ServiciosLoadingState()) {
    on<LoadApiEvent>((event, emit) async {
      try {
        // A refresh keeps the service catalogue visible under the native
        // indicator. Only the first request replaces it with placeholders.
        if (!event.ignoreCache || state is! ServiciosLoadedState) {
          emit(ServiciosLoadingState());
        }
        final empresa = await _courierService.getEmpresa();
        final banners = _loadBanners
            ? await _courierService.getBanners(
                ignoreCache: event.ignoreCache,
              )
            : <BannerImage>[];
        final userProfile = await _courierService.getUserProfile();
        final servicios = await _courierService.getServicios(event.ignoreCache);

        emit(ServiciosLoadedState(servicios, empresa, userProfile, banners));
      } on Exception {
        emit(ServiciosErrorState());
      } finally {
        if (!(event.completed?.isCompleted ?? true)) {
          event.completed!.complete();
        }
      }
    });
  }
}
