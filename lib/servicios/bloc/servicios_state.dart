part of 'servicios_bloc.dart';

abstract class ServiciosState extends Equatable {
  const ServiciosState();
}

class ServiciosLoadingState extends ServiciosState {
  @override
  List<Object> get props => [];
}

class ServiciosErrorState extends ServiciosState {
  @override
  List<Object> get props => [];
}

class ServiciosLoadedState extends ServiciosState {
  final List<Servicio> servicios;

  const ServiciosLoadedState(this.servicios);
  @override
  List<Object?> get props => [servicios];
}
