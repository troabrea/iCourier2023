import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:get_it/get_it.dart';
import 'package:iCourier/services/courierService.dart';
import 'package:iCourier/services/model/prealerta_model.dart';

part 'prealertas_event.dart';
part 'prealertas_state.dart';

class PrealertasBloc extends Bloc<PrealertasEvent, PrealertasState> {
  PrealertasBloc() : super(PrealertasLoadingState()) {
    on<LoadPreAlertasEvent>((event, emit) async {
      try {
        final preAlertas = await GetIt.I<CourierService>().getPrealertas();
        if(preAlertas.isEmpty) {
          emit(PrealertasEmptyState());
        } else {
          emit(PrealertasLoadedState(prealertas: preAlertas));
        }
      } catch(e ) {
        emit(PrealertasErrorState());
      }
    });
  }
}
