part of 'location_bloc.dart';

abstract class LocationBlocEvent extends Equatable {
  const LocationBlocEvent();
}

class LocationBlocCalculateDistanceEvent extends LocationBlocEvent {
  final double destinationLatitude;
  final double destinationLongitude;

  const LocationBlocCalculateDistanceEvent(this.destinationLatitude,
      this.destinationLongitude);

  @override
  List<Object?> get props => [];
}
