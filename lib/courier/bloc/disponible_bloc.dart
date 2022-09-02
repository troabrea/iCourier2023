import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:get_it/get_it.dart';

import '../../services/courierService.dart';

part 'disponible_event.dart';
part 'disponible_state.dart';

class DisponibleBloc extends Bloc<DisponibleEvent, DisponibleState> {
  final _courierService = GetIt.I<CourierService>();

  DisponibleBloc() : super(DisponibleIdleState()) {

    on<DisponiblePagoEnLineaEvent>((event,emit) async {
      await _courierService.launchOnlinePayment();
    });

    on<DisponibleNotificarRetiroEvent>((event,emit) async {
      emit(DisponibleBusyState());
      var result = await _courierService.notificaRetiro();
      emit(DisponibleFinishedState(withErrors:  result.isNotEmpty, errorMessage:  result  ));
      emit(DisponibleIdleState());
    });
  }
}
