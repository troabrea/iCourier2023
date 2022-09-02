import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';

part 'location_state.dart';

part 'location_event.dart';

double calculateDistance(lat1, lon1, lat2, lon2) {
  var p = 0.017453292519943295;
  var c = cos;
  var a = 0.5 -
      c((lat2 - lat1) * p) / 2 +
      c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
  return 12742 * asin(sqrt(a));
}

class LocationBloc extends Bloc<LocationBlocEvent, LocationBlocState> {
  LocationBloc() : super(LocationBlocIdleState()) {
    on<LocationBlocCalculateDistanceEvent>((event, emit) async {
      emit(LocationBlocCalculatingDistinaceState());
      var status = await Permission.locationWhenInUse.status;

      if (status.isDenied) {
        await Permission.locationWhenInUse.request();
      }

      if (await Permission.locationWhenInUse.isGranted) {
        Location location = Location();
        var locationData = await location.getLocation();
        var userLatitude = locationData.latitude ?? 0.00;
        var userLongitude = locationData.longitude ?? 0.00;
        var distanceStr = calculateDistance(
                userLatitude,
                userLongitude,
                event.destinationLatitude,
                event.destinationLongitude)
            .toStringAsFixed(2);
        var distance = "Distancia $distanceStr km";
        emit(LocationBlocDistanceAquiredState(
            userLatitude, userLongitude, distance));
      }
    });
  }
}
