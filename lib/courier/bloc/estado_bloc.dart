import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/services/model/estado_model.dart';
import 'package:meta/meta.dart';

import '../../services/courier_service.dart';

part 'estado_event.dart';
part 'estado_state.dart';

class EstadoBloc extends Bloc<EstadoEvent, EstadoState> {
  EstadoBloc() : super(EstadoInitial()) {
    on<LoadEstadoEvent>((event, emit) async {
      try {
        final estado = await GetIt.I<CourierService>().getEstadoCuenta();
        if(estado.isEmpty) {
          emit(EstadoEmptyState());
        } else {
          emit(EstadoLoadedState(estadoCuenta: estado));
        }
      } catch(e ) {
        emit(EstadoErrorState());
      }
    });
  }
}
