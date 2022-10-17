part of 'noticias_bloc.dart';

abstract class NoticiasEvent extends Equatable {
  const NoticiasEvent();
}

class LoadApiEvent extends NoticiasEvent {
  final bool ignoreCache;
  const LoadApiEvent({this.ignoreCache = false});
  @override
  // AppCenter.track
  List<Object?> get props => [];
}

class NoInternetEvent extends NoticiasEvent {
  @override
  // AppCenter.track
  List<Object?> get props => [];
}
