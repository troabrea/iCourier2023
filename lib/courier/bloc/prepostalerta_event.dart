part of 'prepostalerta_bloc.dart';

abstract class PrePostAlertaEvent extends Equatable {
  const PrePostAlertaEvent();
}

class SendPreAlertaEvent extends PrePostAlertaEvent {
  final PreAlertaModel preAlerta;
  final XFile file;
  const SendPreAlertaEvent(this.file, this.preAlerta);
  @override
  // AppCenter.track
  List<Object?> get props => [file];
}

class SendPostAlertaEvent extends PrePostAlertaEvent {
  final PostAlertaModel postAlerta;
  final XFile file;
  const SendPostAlertaEvent(this.file, this.postAlerta);
  @override
  // AppCenter.track
  List<Object?> get props => [file];
}


