part of 'estado_bloc.dart';

@immutable
abstract class EstadoState {}

class EstadoInitial extends EstadoState {}

class EstadoLoadingState extends EstadoState {
  @override
  List<Object> get props => [];
}

class EstadoEmptyState extends EstadoState {
  @override
  List<Object> get props => [];
}

class EstadoErrorState extends EstadoState {
  @override
  List<Object> get props => [];
}

class EstadoLoadedState extends EstadoState {
  final List<EstadoResponse> estadoCuenta;
  EstadoLoadedState({required this.estadoCuenta});
  @override
  List<Object?> get props => [estadoCuenta];
}