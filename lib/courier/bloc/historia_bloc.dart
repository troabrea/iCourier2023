import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../services/courier_service.dart';
import '../../services/model/recepcion.dart';

part 'historia_event.dart';
part 'historia_state.dart';

class HistoriaBloc extends Bloc<HistoriaEvent, HistoriaState> {
  final _courierService = GetIt.I<CourierService>();

  HistoriaBloc(HistoriaState initialState) : super(initialState) {
    on<LoadApiEvent>((event,emit) async {
      emit(HistoriaLoadingState());
      final recepciones = await _courierService.getHistoriaRecepciones(event.desde,event.hasta);
      emit(recepciones.isNotEmpty ? HistoriaLoadedState(
          recepciones: recepciones,) : HistoriaIdleState() );
    });
  }
}