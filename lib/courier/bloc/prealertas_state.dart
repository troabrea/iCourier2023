part of 'prealertas_bloc.dart';

abstract class PrealertasState extends Equatable {
  const PrealertasState();
}

class PrealertasLoadingState extends PrealertasState {
  @override
  List<Object> get props => [];
}

class PrealertasEmptyState extends PrealertasState {
  @override
  List<Object> get props => [];
}

class PrealertasErrorState extends PrealertasState {
  @override
  List<Object> get props => [];
}

class PrealertasLoadedState extends PrealertasState {
  final List<PreAlertaDto> prealertas;
  const PrealertasLoadedState({required this.prealertas});
  @override
  List<Object?> get props => [prealertas];
}