part of 'facturados_bloc.dart';

@immutable
abstract class FacturadosState {}

class FacturadosInitialState extends FacturadosState {
  @override
  List<Object> get props => [];
}

class FacturadosReadyState extends FacturadosState {
  final List<Recepcion> disponibles;
  final double montoTotal;
  FacturadosReadyState({required this.disponibles, required this.montoTotal});
  @override
  List<Object> get props => [disponibles];
}

class FacturadosFinishedState extends FacturadosState {
  final bool withErrors;
  final String errorMessage;
  FacturadosFinishedState({required this.withErrors, required this.errorMessage});

  @override
  List<Object> get props {
    return [withErrors, errorMessage];
  }
}

class FacturadosBusyState extends FacturadosState {
  @override
  List<Object> get props => [];
}