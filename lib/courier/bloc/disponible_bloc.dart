
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../helpers/dialogs.dart';
import '../../services/courier_service.dart';

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
      if(!await confirmDialog(event.context, "Seguro que desea notificar el retiro de sus paquetes disponibles?", "Si", "No")) {
        return;
      }

      emit(DisponibleBusyState());
      var result = await _courierService.notificaRetiro();
      emit(DisponibleFinishedState(withErrors:  result.isNotEmpty, errorMessage:  result  ));
      emit(DisponibleIdleState());
    });
  }
}
