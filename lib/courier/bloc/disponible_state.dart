part of 'disponible_bloc.dart';

abstract class DisponibleState extends Equatable {
  const DisponibleState();
}

// class DisponibleIdleState extends DisponibleState {
//   @override
//   List<Object> get props => [];
// }

class DisponibleInitialState extends DisponibleState {
  @override
  List<Object> get props => [];
}

class DisponibleReadyState extends DisponibleState {
  final List<Recepcion> disponibles;
  const DisponibleReadyState({required this.disponibles});
  @override
  List<Object> get props => [disponibles];
}

class DisponibleFinishedState extends DisponibleState {
  final bool withErrors;
  final String errorMessage;
  const DisponibleFinishedState({required this.withErrors, required this.errorMessage});

  @override
  List<Object> get props {
    return [withErrors, errorMessage];
  }
}

class DisponibleBusyState extends DisponibleState {
  @override
  List<Object> get props => [];
}
