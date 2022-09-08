import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../services/model/login_model.dart';
import 'package:flutter_cache/flutter_cache.dart' as cache;
import 'package:event/event.dart' as event;
import '../../services/app_events.dart';
import '../../services/courierService.dart';

part 'courier_event.dart';
part 'courier_state.dart';

class CourierBloc extends Bloc<CourierEvent, CourierState> {
  late CourierService courierService;
  late event.Event<LoginChanged> loginChanged;
  late event.Event<CourierRefreshRequested> refreshCourier;

  CourierBloc(CourierState initialState) : super(initialState) {
    courierService = GetIt.I<CourierService>();
    loginChanged = GetIt.I<event.Event<LoginChanged>>();
    refreshCourier = GetIt.I<event.Event<CourierRefreshRequested>>();

    GetIt.I<event.Event<LogoutRequested>>().subscribe((args)  {
      add(LogoutEvent());
    });

    on<CheckLoggedEvent>((event,emit) async {
        emit(CourierIsBusyState());
        var empresa = (await courierService.getEmpresa());
        var sessionId = (await cache.load('sessionId','')).toString();
        var cuenta = (await cache.load('userAccount','')).toString();
        var isLogged = sessionId.isNotEmpty && cuenta.isNotEmpty;
        if(isLogged) {
          emit(CourierIsLoggedState());
        } else {
          emit(CourierIsNotLoggedState(false, empresa.registerUrl ?? ''));
        }
        loginChanged.broadcast(LoginChanged(isLogged, cuenta));
    });

    on<TryLoginEvent>((event,emit) async {
        emit(CourierIsBusyState());
        var empresa = (await courierService.getEmpresa());
        var loginResult = await courierService.getLoginResult(event.usuario, event.clave);
        if(loginResult.sessionId.isNotEmpty) {
          loginChanged.broadcast(LoginChanged(true, event.usuario));
          emit(CourierIsLoggedState());
        } else {
          emit(CourierIsNotLoggedState(true, empresa.registerUrl ?? ''));
        }
    });

    on<UserDidLoginEvent>((event,emit) async {
      loginChanged.broadcast(LoginChanged(true, event.usuario));
      emit(CourierIsLoggedState());
    });

    on<LogoutEvent>( (event,emit) async {
      emit(CourierIsBusyState());
      var empresa = (await courierService.getEmpresa());
      await courierService.saveLoggedOutState();
      loginChanged.broadcast(LoginChanged(false,""));
      emit(CourierIsNotLoggedState(false, empresa.registerUrl ?? ''));
    });

  }

}