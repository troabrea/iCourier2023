import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/services/courier_service.dart';
import 'package:icourier/services/model/recepcion.dart';
import 'package:meta/meta.dart';

part 'facturados_event.dart';
part 'facturados_state.dart';

class FacturadosBloc extends Bloc<FacturadosEvent, FacturadosState> {
  final _courierService = GetIt.I<CourierService>();

  FacturadosBloc(FacturadosState initialState) : super(initialState) {
    on<FacturadosRefreshEvent>((event, emit) async {
      emit(FacturadosBusyState());
      final recepciones = await _courierService.getFacturados();
      final montoTotal = recepciones.fold(0.00, (previousValue, element) => previousValue + element.montoTotal());
      emit(FacturadosReadyState(disponibles: recepciones.where((element) => element.disponible).toList(), montoTotal: montoTotal));

    });
  }
}
