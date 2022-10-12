part of 'noticias_bloc.dart';

abstract class NoticiasState extends Equatable {
  const NoticiasState();
}

class NoticiasLoadingState extends NoticiasState {
  @override
  List<Object> get props => [];
}
class NoticiasErrorState extends NoticiasState {
  @override
  List<Object> get props => [];
}
class NoticiasLoadedState extends NoticiasState {
  final List<Noticia> noticias;
  final List<BannerImage> banners;
  final Empresa empresa;

  const NoticiasLoadedState(this.noticias, this.banners, this.empresa);
  @override
  List<Object?> get props => [noticias];
}
