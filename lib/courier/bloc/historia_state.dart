part of 'historia_bloc.dart';

abstract class HistoriaState extends Equatable {
  const HistoriaState();
}

class HistoriaIdleState extends HistoriaState {
  @override
  List<Object> get props => [];
}

class HistoriaLoadingState extends HistoriaState {
  @override
  List<Object> get props => [];
}

class HistoriaLoadedState extends HistoriaState {
  final List<Recepcion> recepciones;
  const HistoriaLoadedState({required this.recepciones});
  @override
  List<Object?> get props => [recepciones];
}