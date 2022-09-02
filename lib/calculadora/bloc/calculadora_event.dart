part of 'calculadora_bloc.dart';

abstract class CalculadoraEvent extends Equatable {
  const CalculadoraEvent();
}

class CalculateEvent extends CalculadoraEvent {
  late double libras;
  late double valor;
  CalculateEvent(this.libras, this.valor);
  @override
  // TODO: implement props
  List<Object?> get props => [];
}

class NoInternetEvent extends CalculadoraEvent {
  @override
  // TODO: implement props
  List<Object?> get props => [];
}
