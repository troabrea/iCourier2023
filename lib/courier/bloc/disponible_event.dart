part of 'disponible_bloc.dart';

abstract class DisponibleEvent extends Equatable {
  const DisponibleEvent();
}

class DisponibleNotificarRetiroEvent extends DisponibleEvent {
  final BuildContext context;
  DisponibleNotificarRetiroEvent(this.context);
  @override
  // TODO: implement props
  List<Object?> get props => [context];

}

class DisponiblePagoEnLineaEvent extends DisponibleEvent {
  final BuildContext context;
  DisponiblePagoEnLineaEvent(this.context);
  @override
  // TODO: implement props
  List<Object?> get props => [context];

}