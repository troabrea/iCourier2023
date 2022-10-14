part of 'calculadora_bloc.dart';

abstract class CalculadoraEvent extends Equatable {
  const CalculadoraEvent();
}

class CalculatorPrepareEvent extends CalculadoraEvent {
  @override
  // TODO: implement props
  List<Object?> get props => [];
}

class CalculateEvent extends CalculadoraEvent {
  final double libras;
  final double valor;
  final String codigoProducto;
  CalculateEvent(this.libras, this.valor, this.codigoProducto);
  @override
  // TODO: implement props
  List<Object?> get props => [];
}

class NoInternetEvent extends CalculadoraEvent {
  @override
  // TODO: implement props
  List<Object?> get props => [];
}



