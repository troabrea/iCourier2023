part of 'servicios_bloc.dart';

abstract class ServiciosEvent extends Equatable {
  const ServiciosEvent();
}

class LoadApiEvent extends ServiciosEvent {
  final bool ignoreCache;
  const LoadApiEvent({this.ignoreCache = false});
  @override
  // AppCenter.track
  List<Object?> get props => [];
}

class NoInternetEvent extends ServiciosEvent {
  @override
  // AppCenter.track
  List<Object?> get props => [];
}
