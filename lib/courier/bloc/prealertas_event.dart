part of 'prealertas_bloc.dart';

abstract class PrealertasEvent extends Equatable {
  const PrealertasEvent();
}

class LoadPreAlertasEvent extends PrealertasEvent {
  @override
  // AppCenter.track
  List<Object?> get props => [];
}
