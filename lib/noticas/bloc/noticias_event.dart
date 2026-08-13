part of 'noticias_bloc.dart';

abstract class NoticiasEvent extends Equatable {
  const NoticiasEvent();
}

class LoadApiEvent extends NoticiasEvent {
  final bool ignoreCache;
  final Completer<void>? completed;

  const LoadApiEvent({this.ignoreCache = false, this.completed});

  @override
  List<Object?> get props => [ignoreCache];
}

class NoInternetEvent extends NoticiasEvent {
  @override
  // AppCenter.track
  List<Object?> get props => [];
}
