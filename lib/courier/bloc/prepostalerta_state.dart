part of 'prepostalerta_bloc.dart';

abstract class PrePostAlertaState extends Equatable {
  const PrePostAlertaState();
}

class PrePostAlertaIdleState extends PrePostAlertaState {
  @override
  List<Object> get props => [];
}

class PrePostAlertaUpLoadingState extends PrePostAlertaState {
  @override
  List<Object> get props => [];
}

class PrePostAlertaDoneState extends PrePostAlertaState {
  @override
  List<Object> get props => [];
}

class PrePostAlertaErrorState extends PrePostAlertaState {
  @override
  List<Object> get props => [];
}
