part of 'preguntas_bloc.dart';

abstract class PreguntasState extends Equatable {
  const PreguntasState();
}

class PreguntasLoadingState extends PreguntasState {
  @override
  List<Object> get props => [];
}

class PreguntasErrorState extends PreguntasState {
  @override
  List<Object> get props => [];
}

class PreguntasLoadedState extends PreguntasState {
  final List<Pregunta> preguntas;

  const PreguntasLoadedState(this.preguntas);
  @override
  List<Object?> get props => [preguntas];
}
