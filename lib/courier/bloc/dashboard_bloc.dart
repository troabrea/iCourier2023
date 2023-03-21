import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../helpers/dialogs.dart';
import '../../services/courier_service.dart';
import '../../services/model/empresa.dart';
import '../../services/model/recepcion.dart';
import '../../services/model/banner.dart';
import 'package:collection/collection.dart';


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
      final empresa = await _courierService.getEmpresa();
      var puntoRetiro = "";      
      if(empresa.dominio.toUpperCase() == "BMCARGO") {
        puntoRetiro = await optionsDialog(event.context, "Donde desea hacer el retiro?", ["Counter","Drive-Thru","Cancelar"].toList());
        if(puntoRetiro.toUpperCase() == "CANCELAR") {
          return;
        }
        if(puntoRetiro.toUpperCase() == "Counter".toUpperCase() ) {
          puntoRetiro = "AppCounter";
        }
        if(puntoRetiro.toUpperCase() == "Drive-Thru".toUpperCase() ) {
          puntoRetiro = "AppDriveThru";
        }
      } else {
        if(!await confirmDialog(event.context, "Seguro que desea notificar el retiro de sus paquetes disponibles?", "Si", "No")) {
          return;
        }
      }

      emit(DashboardLoadingState());
      var result = await _courierService.notificaRetiro(puntoRetiro: puntoRetiro);

      //
      
      final banners = await _courierService.getBanners();
      final recepciones = await _courierService.getRecepciones(false);
      //final userAccounts = await _courierService.getStoredAccounts();
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

    on<SolicitarDomicilioEvent>((event,emit) async {
      final title = "Recibirá ${event.disponibles.length.toString()} paquete(s)";
      var paquetes = await domicilioDialog(event.context, title, "Solicitar Domicilio", "Cancelar", event.disponibles);
      if(paquetes.isEmpty) {
        return;
      }

      emit(DashboardLoadingState());
      var result = await _courierService.solicitaDomicilio(paquetes);
      emit(DashboardFinishedState(withErrors:  result.isNotEmpty, errorMessage:  result  ));
    });

    on<LoadApiEvent>((event,emit) async {
        emit(DashboardLoadingState());
        final empresa = await _courierService.getEmpresa(ignoreCache: event.forceRefresh);
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