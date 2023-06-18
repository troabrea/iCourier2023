part of 'disponible_bloc.dart';

abstract class DisponibleEvent extends Equatable {
  const DisponibleEvent();
}

class DisponibleNotificarRetiroEvent extends DisponibleEvent {
  final BuildContext context;
  const DisponibleNotificarRetiroEvent(this.context);
  @override
  // AppCenter.track
  List<Object?> get props => [context];

}

class DisponibleRefreshEvent extends DisponibleEvent {
  @override
  // AppCenter.track
  List<Object?> get props => [];
}

class DisponiblePagoEnLineaEvent extends DisponibleEvent {
  final BuildContext context;
  const DisponiblePagoEnLineaEvent(this.context);
  @override
  // AppCenter.track
  List<Object?> get props => [context];
}

class DisponibleDomicilioEvent extends DisponibleEvent {
  final BuildContext context;
  final List<Recepcion> disponibles;
  const DisponibleDomicilioEvent(this.context, this.disponibles);
  @override
  // AppCenter.track
  List<Object?> get props => [context, disponibles];
}