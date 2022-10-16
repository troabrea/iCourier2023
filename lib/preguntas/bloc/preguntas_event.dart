part of 'preguntas_bloc.dart';

abstract class PreguntasEvent extends Equatable {
  const PreguntasEvent();
}

class LoadApiEvent extends PreguntasEvent {
  bool ignoreCache;
  LoadApiEvent({this.ignoreCache = false});
  @override
  // AppCenter.track
  List<Object?> get props => [];
}

class NoInternetEvent extends PreguntasEvent {
  @override
  // AppCenter.track
  List<Object?> get props => [];
}
