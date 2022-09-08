part of 'calculadora_bloc.dart';

abstract class CalculadoraState extends Equatable {
  const CalculadoraState();
}

class CalculadoraIdleState extends CalculadoraState {
  @override
  List<Object> get props => [];
}

class CalculadoraLoadingState extends CalculadoraState {
  @override
  List<Object> get props => [];
}

class CalculadoraLoadedState extends CalculadoraState {
  final double libras;
  final double valorFob;
  final List<CalculadoraResponse> resultados;
  final double subtotal;
  final double impuestos;
  final double total;
  const CalculadoraLoadedState(this.resultados, this.subtotal, this.impuestos, this.total, this.libras, this.valorFob);
  @override
  List<Object?> get props => [resultados, subtotal, impuestos, total, libras, valorFob];
}
