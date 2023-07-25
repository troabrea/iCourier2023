import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../apps/appinfo.dart';
import 'package:flutter_cache/flutter_cache.dart' as cache;
import 'package:event/event.dart' as event;
import '../../services/app_events.dart';
import '../../services/courier_service.dart';

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
          emit(const CourierIsLoggedState());
        } else {
          emit(CourierIsNotLoggedState(false, empresa.registerUrl));
        }
        loginChanged.broadcast(LoginChanged(isLogged, cuenta));
    });

    on<TryLoginEvent>((event,emit) async {
        emit(CourierIsBusyState());
        var empresa = (await courierService.getEmpresa(ignoreCache: true));
        var loginResult = await courierService.getLoginResult(event.usuario, event.clave);
        if(loginResult.sessionId.isNotEmpty) {
          loginChanged.broadcast(LoginChanged(true, event.usuario));
          emit(const CourierIsLoggedState());
        } else {
          emit(CourierIsNotLoggedState(true, empresa.registerUrl));
        }
    });

    on<UserDidLoginEvent>((event,emit) async {
      final appInfo = GetIt.I<AppInfo>();
      final pushUserTopic = (appInfo.metricsPrefixKey == "TLS") ? appInfo.pushChannelTopic + "_" + event.sessionId : appInfo.pushChannelTopic + "_" + event.usuario;
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      messaging.subscribeToTopic(pushUserTopic);

      //
      loginChanged.broadcast(LoginChanged(true, event.usuario));
      emit(const CourierIsLoggedState());
    });

    on<LogoutEvent>( (event,emit) async {
      //
      final cuenta = (await cache.load('userAccount','')).toString();
      final sessionId = (await cache.load('sessionId','')).toString();
      final appInfo = GetIt.I<AppInfo>();
      final pushUserTopic = (appInfo.metricsPrefixKey == "TLS") ? appInfo.pushChannelTopic + "_" + sessionId : appInfo.pushChannelTopic + "_" + cuenta;
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      messaging.unsubscribeFromTopic(pushUserTopic);
      //
      emit(CourierIsBusyState());
      var empresa = (await courierService.getEmpresa());
      await courierService.saveLoggedOutState();
      loginChanged.broadcast(LoginChanged(false,""));
      emit(CourierIsNotLoggedState(false, empresa.registerUrl));
    });

  }

}