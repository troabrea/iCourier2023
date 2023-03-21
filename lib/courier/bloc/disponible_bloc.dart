
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../helpers/dialogs.dart';
import '../../services/courier_service.dart';
import '../../services/model/recepcion.dart';

part 'disponible_event.dart';
part 'disponible_state.dart';

class DisponibleBloc extends Bloc<DisponibleEvent, DisponibleState> {
  final _courierService = GetIt.I<CourierService>();

  DisponibleBloc() : super(DisponibleIdleState()) {

    on<DisponiblePagoEnLineaEvent>((event,emit) async {
      if(!await confirmDialog(event.context, "Seguro que desea realizar el pago en linea de sus paquetes disponibles?", "Si", "No")) {
        return;
      }
      await _courierService.launchOnlinePayment();
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
      emit(DisponibleFinishedState(withErrors:  result.isNotEmpty, errorMessage:  result  ));
      emit(DisponibleIdleState());
    });

    on<DisponibleDomicilioEvent>((event,emit) async {
      var paquetes = await domicilioDialog(event.context, "Seleccione Paquetes", "Solicitar Domicilio", "Cancelar", event.disponibles);
      if(paquetes.isEmpty) {
        return;
      }

      emit(DisponibleBusyState());
      var result = await _courierService.solicitaDomicilio(paquetes);
      emit(DisponibleFinishedState(withErrors:  result.isNotEmpty, errorMessage:  result  ));
      emit(DisponibleIdleState());
    });

  }
}
