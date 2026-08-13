part of 'courier_bloc.dart';

abstract class CourierState extends Equatable {
  const CourierState();
}

class CourierIsBusyState extends CourierState {
  @override
  // AppCenter.track
  List<Object> get props => [];
}

/// Keeps the login surface in place while the credentials are verified.
class CourierIsSubmittingState extends CourierState {
  const CourierIsSubmittingState(this.registerUrl);

  final String registerUrl;

  @override
  List<Object> get props => [registerUrl];
}

class CourierIsErrorState extends CourierState {
  @override
  // AppCenter.track
  List<Object> get props => [];
}

class CourierIsLoggedState extends CourierState {
  const CourierIsLoggedState();
  @override
  // AppCenter.track
  List<Object> get props => [];
}

class CourierIsNotLoggedState extends CourierState {
  final bool showError;
  final String registerUrl;
  const CourierIsNotLoggedState(this.showError, this.registerUrl);

  @override
  // AppCenter.track
  List<Object> get props => [showError];
}
