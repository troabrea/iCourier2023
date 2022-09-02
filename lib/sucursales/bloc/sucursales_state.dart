part of 'sucursales_bloc.dart';

abstract class SucursalesState extends Equatable {
  const SucursalesState();
}

class SucursalesLoadingState extends SucursalesState {
  @override
  List<Object> get props => [];
}

class SucursalesErrorState extends SucursalesState {
  @override
  List<Object> get props => [];
}

class SucursalesLoadedState extends SucursalesState {
  final List<Sucursal> sucursales;
  final Map<MarkerId, Marker> markers;

  const SucursalesLoadedState(this.sucursales, this.markers);
  @override
  List<Object?> get props => [sucursales, markers];
}

