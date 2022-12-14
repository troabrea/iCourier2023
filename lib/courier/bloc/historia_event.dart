part of 'historia_bloc.dart';

abstract class HistoriaEvent extends Equatable {
  const HistoriaEvent();
}

class LoadApiEvent extends HistoriaEvent {
  final DateTime desde;
  final DateTime hasta;
  const LoadApiEvent(this.desde,this.hasta);
  @override
  // AppCenter.track
  List<Object?> get props => [desde, hasta];
}