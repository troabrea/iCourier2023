part of 'calculadora_bloc.dart';

abstract class CalculadoraEvent extends Equatable {
  const CalculadoraEvent();
}

class CalculatorPrepareEvent extends CalculadoraEvent {
  @override
  List<Object?> get props => [];
}

class CalculateEvent extends CalculadoraEvent {
  final double libras;
  final double valor;
  final String codigoProducto;
  CalculateEvent(this.libras, this.valor, this.codigoProducto);
  @override
  List<Object?> get props => [];
}

class NoInternetEvent extends CalculadoraEvent {
  @override
  // AppCenter.track
  List<Object?> get props => [];
}



