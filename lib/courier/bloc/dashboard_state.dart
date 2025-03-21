part of 'dashboard_bloc.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();
}

class DashboardLoadingState extends DashboardState {
  @override
  List<Object> get props => [];
}

class DashboardFinishedState extends DashboardState {
  final bool withErrors;
  final String errorMessage;
  const DashboardFinishedState({required this.withErrors, required this.errorMessage});

  @override
  List<Object> get props {
    return [withErrors, errorMessage];
  }
}

class DashboardLoadedState extends DashboardState {
  final Empresa empresa;
  final Puntos puntos;
  final String moreInfoText;
  final String moreInfoUrl;
  final String reclamoUrl;
  final String referirUrl;
  final List<BannerImage> banners;
  final List<Recepcion> recepciones;
  final int recepcionesCount;
  final int disponiblesCount;
  final int retenidosCount;
  final double montoTotal;
  const DashboardLoadedState({required this.reclamoUrl, required this.moreInfoText, required this.moreInfoUrl, required this.referirUrl, required this.banners,required this.recepciones, required this.recepcionesCount, required this.disponiblesCount, required this.retenidosCount, required this.empresa, required this.montoTotal, required this.puntos});
  @override
  List<Object?> get props => [banners,recepciones, recepcionesCount, disponiblesCount, retenidosCount, puntos, moreInfoText, moreInfoUrl];
}