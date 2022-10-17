part of 'courier_bloc.dart';

abstract class CourierEvent extends Equatable {
  const CourierEvent();
}

class CheckLoggedEvent extends CourierEvent {
  @override
  // AppCenter.track
  List<Object?> get props => [];
}

class TryLoginEvent extends CourierEvent {
  final String usuario;
  final String clave;
  const TryLoginEvent(this.usuario, this.clave);
  @override
  // AppCenter.track
  List<Object?> get props => [];
}

class UserDidLoginEvent extends CourierEvent {
  final String usuario;
  final bool forceRefresh;
  const UserDidLoginEvent(this.usuario, {this.forceRefresh = false});
  @override
  // AppCenter.track
  List<Object?> get props => [usuario];
}

class LogoutEvent extends CourierEvent {
  @override
  // AppCenter.track
  List<Object?> get props => [];
}

