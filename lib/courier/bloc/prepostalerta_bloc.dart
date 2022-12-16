import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/courier_service.dart';
import '../../services/model/postalerta_model.dart';
import '../../services/model/prealerta_model.dart';

part 'prepostalerta_event.dart';
part 'prepostalerta_state.dart';

class PrePostAlertaBloc extends Bloc<PrePostAlertaEvent, PrePostAlertaState> {
  final CourierService _courierService;
  // final ConnectivityService _connectivityService;

  PrePostAlertaBloc(this._courierService) : super(PrePostAlertaIdleState()) {
    on<SendPreAlertaEvent>((event,emit) async {
      emit(PrePostAlertaUpLoadingState());
      final resultStr = await _courierService.sendPreAlerta(event.preAlerta, event.file);
      final result = resultStr.isEmpty || resultStr.toUpperCase() == "OK";
      emit(result ? PrePostAlertaDoneState() : PrePostAlertaErrorState(errorMessage: resultStr));
    });

    on<SendPostAlertaEvent>((event,emit) async {
      emit(PrePostAlertaUpLoadingState());
      var resultStr = await _courierService.sendPostAlerta(event.postAlerta, event.file);
      final result = resultStr.isEmpty || resultStr.toUpperCase() == "OK";
      emit(result ? PrePostAlertaDoneState() : PrePostAlertaErrorState(errorMessage: resultStr));
    });
  }
}
