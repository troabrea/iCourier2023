import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';
import '../../services/app_events.dart';
import '../../services/courierService.dart';
import '../../services/model/calculadora_model.dart';
import 'package:collection/collection.dart';
import 'package:event/event.dart' as event;
import '../../services/model/producto.dart';

part 'calculadora_event.dart';
part 'calculadora_state.dart';

class CalculadoraBloc extends Bloc<CalculadoraEvent, CalculadoraState> {
  final CourierService _courierService;
  // final ConnectivityService _connectivityService;

  CalculadoraBloc(this._courierService) : super(CalculadoraLoadingState()) {

    GetIt.I<event.Event<LoginChanged>>().subscribe((args)  {
      add(CalculatorPrepareEvent());
    });


    on<CalculatorPrepareEvent>((event,emit) async {
      emit(CalculadoraLoadingState());
      final empresa = await _courierService.getEmpresa();
      final products = await _courierService.getProductos(false);
      if(products.isEmpty) {
        products.add(Producto(registroId: Uuid().toString(), empresa: empresa.registroId, titulo: 'FLETE', codigo: empresa.calculadoraProducto, orden: 1, deleted: false));
      }
      final productoDefault = products.firstWhere((element) => element.codigo == empresa.calculadoraProducto);
      products.sort((a,b) => a.orden.compareTo(b.orden));
      emit(CalculadoraPreparedState(products, productoDefault));
    });

    on<CalculateEvent>((event,emit) async {
        emit(CalculadoraLoadingState());
        var result = await _courierService.getCalculadoraResult(event.libras, event.valor, producto: event.codigoProducto);
        var subtotal = result.isNotEmpty ? result.map((e) => e.bruto).toList().sum : 0.0;
        var impuesto = result.isNotEmpty ? result.map((e) => e.impuesto).toList().sum : 0.0;
        var total = result.isNotEmpty ? result.map((e) => e.neto).toList().sum : 0.0;
        emit(CalculadoraLoadedState(result, subtotal, impuesto, total, event.libras, event.valor));
    });
  }
}
