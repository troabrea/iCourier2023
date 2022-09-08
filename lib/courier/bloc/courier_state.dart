part of 'courier_bloc.dart';

abstract class CourierState extends Equatable {
  const CourierState();
}

class CourierIsBusyState extends CourierState{
  @override
  // TODO: implement props
  List<Object> get props => [];
}

class CourierIsLoggedState extends CourierState{
  CourierIsLoggedState();
  @override
  // TODO: implement props
  List<Object> get props => [];
}

class CourierIsNotLoggedState extends CourierState{
  final bool showError;
  final String registerUrl;
  const CourierIsNotLoggedState(this.showError, this.registerUrl);

  @override
  // TODO: implement props
  List<Object> get props => [showError];
}