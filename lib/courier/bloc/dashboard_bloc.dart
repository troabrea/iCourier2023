import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:iCourier/helpers/dialogs.dart';
import '../../services/app_events.dart';
import '../../services/courierService.dart';
import '../../services/model/empresa.dart';
import '../../services/model/recepcion.dart';
import 'package:flutter_cache/flutter_cache.dart' as cache;
import 'package:event/event.dart' as event;
import 'package:url_launcher/url_launcher.dart';
import '../../services/model/banner.dart';
import 'package:collection/collection.dart';

import '../../services/model/login_model.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final _courierService = GetIt.I<CourierService>();

  DashboardBloc(DashboardState initialState) : super(initialState) {

    on<StoreCurrentAccountEvent>((event,emit) async {
      await _courierService.addCurrentAccountToStore();
    });

    on<OnlinePaymentRequestEvent>((event,emit) async {
      if(!await confirmDialog(event.context, "Seguro que desea realizar el pago en linea?", "Si", "No")) {
        return;
      }
      await _courierService.launchOnlinePayment();
    });

    on<NotificarRetiroEvent>((event,emit) async {

      if(!await confirmDialog(event.context, "Seguro que desea notificar el retiro de sus paquetes disponibles?", "Si", "No")) {
        return;
      }

      emit(DashboardLoadingState());
      var result = await _courierService.notificaRetiro();

      //
      final empresa = await _courierService.getEmpresa();
      final banners = await _courierService.getBanners();
      final recepciones = await _courierService.getRecepciones(false);
      final userAccounts = await _courierService.getStoredAccounts();
      final recepcionesCount = recepciones.length;

      final retenidosCount = recepciones.where((element) => element.retenido == true).length;

      var disponibles = recepciones.where((element) => element.disponible == true).toList();
      final disponiblesCount = disponibles.length;
      final montoTotal = disponibles.map((e) => e.montoTotal()).toList().sum;
      //

      emit(DashboardFinishedState(withErrors:  result.isNotEmpty, errorMessage:  result  ));
      emit(DashboardLoadedState(empresa: empresa,
          banners:  banners,
          recepciones: recepciones,
          recepcionesCount:  recepcionesCount,
          disponiblesCount: disponiblesCount,
          montoTotal: montoTotal,
          retenidosCount: retenidosCount,));
    });

    on<LoadApiEvent>((event,emit) async {
        emit(DashboardLoadingState());
        final empresa = await _courierService.getEmpresa();
        final banners = await _courierService.getBanners();
        final recepciones = await _courierService.getRecepciones(event.forceRefresh);

        final recepcionesCount = recepciones.length;

        final retenidosCount = recepciones.where((element) => element.retenido == true).length;

        var disponibles = recepciones.where((element) => element.disponible == true).toList();
        final disponiblesCount = disponibles.length;
        final montoTotal = disponibles.map((e) => e.montoTotal()).toList().sum;

        emit(DashboardLoadedState( empresa: empresa,
            banners:  banners,
            recepciones: recepciones,
            recepcionesCount:  recepcionesCount,
            disponiblesCount: disponiblesCount,
            montoTotal: montoTotal,
            retenidosCount: retenidosCount,
            ));
    });
  }
}