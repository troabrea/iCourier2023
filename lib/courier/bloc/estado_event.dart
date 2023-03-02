part of 'estado_bloc.dart';

@immutable
abstract class EstadoEvent {}

class LoadEstadoEvent extends EstadoEvent {
  @override
  // AppCenter.track
  List<Object?> get props => [];
}