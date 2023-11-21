import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/services/model/puntos_model.dart';
import '../../helpers/dialogs.dart';
import '../../services/courier_service.dart';
import '../../services/model/empresa.dart';
import '../../services/model/recepcion.dart';
import '../../services/model/banner.dart';
import 'package:collection/collection.dart';


part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final _courierService = GetIt.I<CourierService>();

  DashboardBloc(DashboardState initialState) : super(initialState) {

    on<StoreCurrentAccountEvent>((event,emit) async {
      await _courierService.addCurrentAccountToStore();
    });

    on<OnlinePaymentRequestEvent>((event,emit) async {
      if(!await confirmDialog(event.context, "seguro_pagar_en_linea".tr(), "si".tr(), "no".tr())) {
        return;
      }
      await _courierService.launchOnlinePayment();
    });

    on<NotificarRetiroEvent>((event,emit) async {
      final empresa = await _courierService.getEmpresa();
      var puntoRetiro = "";
      if(empresa.dominio.toUpperCase() == "BMCARGO") {
        puntoRetiro = await optionsDialog(event.context, "donde_notificar_retiro".tr(), ["Counter","Drive-Thru","cancelar".tr()].toList());
        if(puntoRetiro.toUpperCase() == "cancelar".tr().toUpperCase()) {
          return;
        }
        if(puntoRetiro.toUpperCase() == "Counter".toUpperCase() ) {
          puntoRetiro = "AppCounter";
        }
        if(puntoRetiro.toUpperCase() == "Drive-Thru".toUpperCase() ) {
          puntoRetiro = "AppDriveThru";
        }
      } else {
        if(!await confirmDialog(event.context, "seguro_notificar_retiro".tr(), "si".tr(), "no".tr())) {
          return;
        }
      }

      emit(DashboardLoadingState());
      var result = await _courierService.notificaRetiro(puntoRetiro: puntoRetiro);

      //
      
      final banners = await _courierService.getBanners();
      final recepciones = await _courierService.getRecepciones(true);
      final puntos = empresa.hasPointsModule ? await _courierService.getPuntos() : Puntos.empty();
      final moreInfoText = await _courierService.empresaOptionValue("MoreInfoText");
      final moreInfoUrl = await _courierService.empresaOptionValue("MoreInfoUrl");

      //final userAccounts = await _courierService.getStoredAccounts();
      final recepcionesCount = recepciones.length;

      final retenidosCount = recepciones.where((element) => element.retenido == true).length;

      var disponibles = recepciones.where((element) => element.disponible == true).toList();
      final disponiblesCount = disponibles.length;
      final montoTotal = disponibles.map((e) => e.montoTotal()).toList().sum;
      //

      emit(DashboardFinishedState(withErrors:  result.isNotEmpty, errorMessage:  result  ));
      emit(DashboardLoadedState(empresa: empresa,
          banners:  banners,
          recepciones: recepciones,
          recepcionesCount:  recepcionesCount,
          disponiblesCount: disponiblesCount,
          montoTotal: montoTotal,
          retenidosCount: retenidosCount,
          puntos: puntos,
          moreInfoUrl: moreInfoUrl,
          moreInfoText: moreInfoText
      ));
    });

    on<SolicitarDomicilioEvent>((event,emit) async {
      final title = "recibira_n_paquetes".tr(args: [event.disponibles.length.toString()]);
      var paquetes = await domicilioDialog(event.context, title, "solicitar_domicilio".tr(), "cancelar".tr(), event.disponibles);
      if(paquetes.isEmpty) {
        return;
      }

      emit(DashboardLoadingState());
      var result = await _courierService.solicitaDomicilio(paquetes);
      emit(DashboardFinishedState(withErrors:  result.isNotEmpty, errorMessage:  result  ));
    });

    on<LoadApiEvent>((event,emit) async {
      try {
        emit(DashboardLoadingState());
        final empresa = await _courierService.getEmpresa(ignoreCache: event.forceRefresh);
        final banners = await _courierService.getBanners();
        final recepciones = await _courierService.getRecepciones(event.forceRefresh);
        final puntos = empresa.hasPointsModule ? await _courierService.getPuntos() : Puntos.empty();
        final moreInfoText = await _courierService.empresaOptionValue("MoreInfoText");
        final moreInfoUrl = await _courierService.empresaOptionValue("MoreInfoUrl");
        final recepcionesCount = recepciones.length;

        final retenidosCount = recepciones.where((element) => element.retenido == true).length;

        var disponibles = recepciones.where((element) => element.disponible == true).toList();
        final disponiblesCount = disponibles.length;
        final montoTotal = disponibles.map((e) => e.montoTotal()).toList().sum;

        emit(DashboardLoadedState( empresa: empresa,
            banners:  banners,
            recepciones: recepciones,
            recepcionesCount:  recepcionesCount,
            disponiblesCount: disponiblesCount,
            montoTotal: montoTotal,
            retenidosCount: retenidosCount,
            puntos: puntos,
            moreInfoText: moreInfoText,
            moreInfoUrl: moreInfoUrl
        ));
      } catch(e) {
        emit(DashboardFinishedState(withErrors: true, errorMessage: "error_favor_reintentar".tr()));
      }

    });
  }
}