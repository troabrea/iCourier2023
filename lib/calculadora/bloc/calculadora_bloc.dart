import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/courierService.dart';
import '../../services/model/calculadora_model.dart';
import 'package:collection/collection.dart';

part 'calculadora_event.dart';
part 'calculadora_state.dart';

class CalculadoraBloc extends Bloc<CalculadoraEvent, CalculadoraState> {
  final CourierService _courierService;
  // final ConnectivityService _connectivityService;

  CalculadoraBloc(this._courierService) : super(CalculadoraIdleState()) {
    on<CalculateEvent>((event,emit) async {
        emit(CalculadoraLoadingState());
        var result = await _courierService.getCalculadoraResult(event.libras, event.valor);
        var subtotal = result.isNotEmpty ? result.map((e) => e.bruto).toList().sum : 0.0;
        var impuesto = result.isNotEmpty ? result.map((e) => e.impuesto).toList().sum : 0.0;
        var total = result.isNotEmpty ? result.map((e) => e.neto).toList().sum : 0.0;
        emit(CalculadoraLoadedState(result, subtotal, impuesto, total, event.libras, event.valor));
    });
  }
}
