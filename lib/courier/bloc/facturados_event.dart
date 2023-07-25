part of 'facturados_bloc.dart';

@immutable
abstract class FacturadosEvent {}

class FacturadosRefreshEvent extends FacturadosEvent {
  @override
  // AppCenter.track
  List<Object?> get props => [];
}

class FacturadosPagoEnLineaEvent extends FacturadosEvent {
  final BuildContext context;
  FacturadosPagoEnLineaEvent(this.context);
  @override
  // AppCenter.track
  List<Object?> get props => [context];
}

