part of 'dashboard_bloc.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
}

class LoadApiEvent extends DashboardEvent {
  final bool forceRefresh;
  const LoadApiEvent(this.forceRefresh);
  @override
  // TODO: implement props
  List<Object?> get props => [forceRefresh];
}

class OnlinePaymentRequestEvent extends DashboardEvent {
  @override
  List<Object?> get props => [];
}

class NotificarRetiroEvent extends DashboardEvent {
  @override
  List<Object?> get props => [];
}

class StoreCurrentAccountEvent extends DashboardEvent {
  @override
  List<Object?> get props => [];
}