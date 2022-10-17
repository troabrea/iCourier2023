part of 'sucursales_bloc.dart';

abstract class SucursalesEvent extends Equatable {
  const SucursalesEvent();
}

class LoadApiEvent extends SucursalesEvent {
  final bool ignoreCache;
  const LoadApiEvent({this.ignoreCache = false});
  @override
  List<Object?> get props => [];
}

class NoInternetEvent extends SucursalesEvent {
  @override
  List<Object?> get props => [];
}
