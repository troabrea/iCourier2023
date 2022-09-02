part of 'location_bloc.dart';

abstract class LocationBlocState extends Equatable {
  const LocationBlocState();
}

class LocationBlocIdleState extends LocationBlocState {
  @override
  List<Object> get props => [];
}

class LocationBlocCalculatingDistinaceState extends LocationBlocState {
  @override
  List<Object> get props => [];
}

class LocationBlocDistanceAquiredState extends LocationBlocState {
  final double latitude;
  final double longitude;
  final String distance;

  const LocationBlocDistanceAquiredState(this.latitude, this.longitude,
      this.distance);

  @override
  List<Object> get props => [latitude, longitude];
}
