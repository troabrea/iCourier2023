part of 'servicios_bloc.dart';

abstract class ServiciosState extends Equatable {
  const ServiciosState();
}

class ServiciosLoadingState extends ServiciosState {
  @override
  List<Object> get props => [];
}

class ServiciosErrorState extends ServiciosState {
  @override
  List<Object> get props => [];
}

class ServiciosLoadedState extends ServiciosState {
  final List<Servicio> servicios;
  final List<BannerImage> banners;
  final Empresa empresa;
  final UserProfile userProfile;
  const ServiciosLoadedState(this.servicios, this.empresa, this.userProfile, this.banners);
  @override
  List<Object?> get props => [servicios, empresa, userProfile, banners];
}
