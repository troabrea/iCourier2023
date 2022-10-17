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

class DisponiblePagoEnLineaEvent extends DisponibleEvent {
  final BuildContext context;
  const DisponiblePagoEnLineaEvent(this.context);
  @override
  // AppCenter.track
  List<Object?> get props => [context];

}