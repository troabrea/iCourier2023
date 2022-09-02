part of 'servicios_bloc.dart';

abstract class ServiciosEvent extends Equatable {
  const ServiciosEvent();
}

class LoadApiEvent extends ServiciosEvent {
  bool ignoreCache;
  LoadApiEvent({this.ignoreCache = false});
  @override
  // TODO: implement props
  List<Object?> get props => [];
}

class NoInternetEvent extends ServiciosEvent {
  @override
  // TODO: implement props
  List<Object?> get props => [];
}
