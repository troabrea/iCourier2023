import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/courierService.dart';

import '../../services/connectivityService.dart';
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
        emit(PreguntasLoadingState());
        final preguntas = await _courierService.getPreguntas(event.ignoreCache);
        emit(PreguntasLoadedState(preguntas));
      } catch (ex) {
        emit(PreguntasErrorState());
      }
    });
  }
}
