
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/services/app_events.dart';

import '../../helpers/dialogs.dart';
import '../../services/courier_service.dart';
import '../../services/model/recepcion.dart';
import 'package:event/event.dart' as event;

part 'disponible_event.dart';
part 'disponible_state.dart';

class DisponibleBloc extends Bloc<DisponibleEvent, DisponibleState> {
  final _courierService = GetIt.I<CourierService>();
  late event.Event<CourierRefreshRequested> refreshCourier;

  DisponibleBloc(DisponibleState initialState) : super(initialState) {
    refreshCourier = GetIt.I<event.Event<CourierRefreshRequested>>();
    on<DisponiblePagoEnLineaEvent>((event,emit) async {
      if(!await confirmDialog(event.context, "Seguro que desea realizar el pago en linea de sus paquetes disponibles?", "Si", "No")) {
        return;
      }
      await _courierService.launchOnlinePayment();
    });

    on<DisponibleRefreshEvent>((event,emit) async {
      emit(DisponibleBusyState());
      var recepciones = await _courierService.getRecepciones(true);
      emit(DisponibleReadyState(disponibles: recepciones.where((element) => element.disponible).toList()));
    });

    on<DisponibleNotificarRetiroEvent>((event,emit) async {
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
        if (!await confirmDialog(event.context,
            "Seguro que desea notificar el retiro de sus paquetes disponibles?",
            "Si", "No")) {
          return;
        }
      }

      emit(DisponibleBusyState());
      var result = await _courierService.notificaRetiro(puntoRetiro: puntoRetiro);
      var recepciones = await _courierService.getRecepciones(true);
      emit(DisponibleFinishedState(withErrors:  result.isNotEmpty, errorMessage:  result  ));
      emit(DisponibleReadyState(disponibles: recepciones.where((element) => element.disponible).toList()));
    });

    on<DisponibleDomicilioEvent>((event,emit) async {
      var paquetes = await domicilioDialog(event.context, "Seleccione Paquetes", "Solicitar Domicilio", "Cancelar", event.disponibles);
      if(paquetes.isEmpty) {
        return;
      }

      emit(DisponibleBusyState());
      var result = await _courierService.solicitaDomicilio(paquetes);
      var recepciones = await _courierService.getRecepciones(true);
      emit(DisponibleFinishedState(withErrors:  result.isNotEmpty, errorMessage:  result  ));
      emit(DisponibleReadyState(disponibles: recepciones.where((element) => element.disponible).toList()));
    });

  }
}
