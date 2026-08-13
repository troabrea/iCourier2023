part of 'servicios_bloc.dart';

abstract class ServiciosEvent extends Equatable {
  const ServiciosEvent();
}

class LoadApiEvent extends ServiciosEvent {
  final bool ignoreCache;
  final Completer<void>? completed;

  const LoadApiEvent({this.ignoreCache = false, this.completed});

  @override
  List<Object?> get props => [ignoreCache];
}

class NoInternetEvent extends ServiciosEvent {
  @override
  // AppCenter.track
  List<Object?> get props => [];
}
