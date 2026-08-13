part of 'preguntas_bloc.dart';

abstract class PreguntasEvent extends Equatable {
  const PreguntasEvent();
}

class LoadApiEvent extends PreguntasEvent {
  final bool ignoreCache;
  final Completer<void>? completed;

  const LoadApiEvent({this.ignoreCache = false, this.completed});

  @override
  List<Object?> get props => [ignoreCache];
}

class NoInternetEvent extends PreguntasEvent {
  @override
  // AppCenter.track
  List<Object?> get props => [];
}
