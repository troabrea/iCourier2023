part of 'courier_bloc.dart';

abstract class CourierEvent extends Equatable {
  const CourierEvent();
}

class CheckLoggedEvent extends CourierEvent {
  @override
  // TODO: implement props
  List<Object?> get props => [];
}

class TryLoginEvent extends CourierEvent {
  late String usuario;
  late String clave;
  TryLoginEvent(this.usuario, this.clave);
  @override
  // TODO: implement props
  List<Object?> get props => [];
}

class UserDidLoginEvent extends CourierEvent {
  String usuario;
  bool forceRefresh;
  UserDidLoginEvent(this.usuario, {this.forceRefresh = false});
  @override
  // TODO: implement props
  List<Object?> get props => [usuario];
}

class LogoutEvent extends CourierEvent {
  @override
  // TODO: implement props
  List<Object?> get props => [];
}

