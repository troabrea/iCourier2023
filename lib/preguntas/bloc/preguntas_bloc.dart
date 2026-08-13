import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../services/courier_service.dart';
import '../../services/model/pregunta.dart';

part 'preguntas_event.dart';
part 'preguntas_state.dart';

class PreguntasBloc extends Bloc<PreguntasEvent, PreguntasState> {
  final CourierService _courierService;
  //final ConnectivityService _connectivityService;

  PreguntasBloc(this._courierService) : super(PreguntasLoadingState()) {
    // _connectivityService.connectivityStream.stream.listen((event) {
    //   if (event == ConnectivityResult.none) {
    //     print('no internet');
    //     add(NoInternetEvent());
    //   } else {
    //     print('yes internet');
    //     add(LoadApiEvent());
    //   }
    // });

    on<LoadApiEvent>((event, emit) async {
      try {
        // Pull-to-refresh keeps the answers readable beneath the native
        // indicator. Only the first request replaces the screen with bones.
        if (!event.ignoreCache || state is! PreguntasLoadedState) {
          emit(PreguntasLoadingState());
        }
        final preguntas = await _courierService.getPreguntas(event.ignoreCache);
        emit(PreguntasLoadedState(preguntas));
      } on Exception {
        emit(PreguntasErrorState());
      } finally {
        if (!(event.completed?.isCompleted ?? true)) {
          event.completed!.complete();
        }
      }
    });
  }
}
