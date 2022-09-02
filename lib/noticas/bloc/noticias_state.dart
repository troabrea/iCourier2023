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

  const NoticiasLoadedState(this.noticias, this.banners);
  @override
  List<Object?> get props => [noticias];
}
