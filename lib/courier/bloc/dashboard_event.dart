part of 'dashboard_bloc.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
}

class LoadApiEvent extends DashboardEvent {
  final bool forceRefresh;
  const LoadApiEvent(this.forceRefresh);
  @override
  // AppCenter.track
  List<Object?> get props => [forceRefresh];
}

class ReferirAmigoRequestEvent extends DashboardEvent {
  final BuildContext context;
  const ReferirAmigoRequestEvent(this.context);
  @override
  List<Object?> get props => [context];
}

class OnlinePaymentRequestEvent extends DashboardEvent {
  final BuildContext context;
  const OnlinePaymentRequestEvent(this.context);
  @override
  List<Object?> get props => [context];
}

class NotificarRetiroEvent extends DashboardEvent {
  final BuildContext context;
  const NotificarRetiroEvent(this.context);
  @override
  List<Object?> get props => [context];
}

class SolicitarDomicilioEvent extends DashboardEvent {
  final BuildContext context;
  final List<Recepcion> disponibles;
  const SolicitarDomicilioEvent(this.context, this.disponibles);
  @override
  // AppCenter.track
  List<Object?> get props => [context, disponibles];
}

class StoreCurrentAccountEvent extends DashboardEvent {
  @override
  List<Object?> get props => [];
}