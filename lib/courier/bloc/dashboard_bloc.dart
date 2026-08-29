import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/services/model/mensaje.dart';
import 'package:icourier/services/model/puntos_model.dart';
import '../../helpers/dialogs.dart';
import '../../services/courier_service.dart';
import '../../services/model/empresa.dart';
import '../../services/model/recepcion.dart';
import '../../services/model/banner.dart';
import '../../theme/brand_config.dart';
import 'package:collection/collection.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final _courierService = GetIt.I<CourierService>();
  var _loadGeneration = 0;

  DashboardBloc(super.initialState) {
    on<StoreCurrentAccountEvent>((event, emit) async {
      await _courierService.addCurrentAccountToStore();
    });

    on<OnlinePaymentRequestEvent>((event, emit) async {
      if (!event.context.mounted) return;
      if (!await confirmDialog(
          event.context, "seguro_pagar_en_linea".tr(), "si".tr(), "no".tr())) {
        return;
      }
      final context = event.context;
      if (!context.mounted) return;

      await _courierService.launchOnlinePayment(event.context);
    });

    on<ReferirAmigoRequestEvent>((event, emit) async {
      await _courierService.launchReferirAmigoUrl();
    });

    bool isNotifying = false;
    on<NotificarRetiroEvent>((event, emit) async {
      try {
        if (isNotifying) {
          return;
        }
        isNotifying = true;
        final empresa = await _courierService.getEmpresa();
        final context = event.context;
        if (!context.mounted) return;
        var puntoRetiro = '';
        final pickupModes = GetIt.I<BrandConfig>().capabilities.pickupModes;
        if (pickupModes.isNotEmpty) {
          puntoRetiro = await optionsDialog(
              context,
              "donde_notificar_retiro".tr(),
              [...pickupModes.map((mode) => mode.label), "cancelar".tr()]);
          if (puntoRetiro.toUpperCase() == "cancelar".tr().toUpperCase()) {
            return;
          }
          puntoRetiro =
              pickupModes.firstWhere((mode) => mode.label == puntoRetiro).value;
        } else {
          if (!await confirmDialog(
              context, "seguro_notificar_retiro".tr(), "si".tr(), "no".tr())) {
            return;
          }
        }

        emit(DashboardLoadingState());
        var result =
            await _courierService.notificaRetiro(puntoRetiro: puntoRetiro);

        //

        final banners = await _courierService.getBanners();
        final mensajes = await _courierService.getMensajes();
        final recepciones = await _courierService.getRecepciones(true);
        final puntos = empresa.hasPointsModule
            ? await _courierService.getPuntos()
            : Puntos.empty();
        final moreInfoText =
            await _courierService.empresaOptionValue("MoreInfoText");
        final moreInfoUrl =
            await _courierService.empresaOptionValue("MoreInfoUrl");
        final reclamoUrl =
            await _courierService.empresaOptionValue("ReclamoUrl");
        final referirUrl =
            await _courierService.empresaOptionValue("ReferirUrl");
        //final userAccounts = await _courierService.getStoredAccounts();
        final recepcionesCount = recepciones.length;

        final retenidosCount =
            recepciones.where((element) => element.retenido == true).length;

        var disponibles =
            recepciones.where((element) => element.disponible == true).toList();
        final disponiblesCount = disponibles.length;
        final montoTotal = disponibles.map((e) => e.montoTotal()).toList().sum;
        //

        emit(DashboardFinishedState(
            withErrors: result.isNotEmpty, errorMessage: result));
        emit(DashboardLoadedState(
            empresa: empresa,
            banners: banners,
            mensajes: mensajes,
            recepciones: recepciones,
            recepcionesCount: recepcionesCount,
            disponiblesCount: disponiblesCount,
            montoTotal: montoTotal,
            retenidosCount: retenidosCount,
            puntos: puntos,
            moreInfoUrl: moreInfoUrl,
            moreInfoText: moreInfoText,
            reclamoUrl: reclamoUrl,
            referirUrl: referirUrl));
        isNotifying = true;
      } finally {
        isNotifying = false;
      }
    });

    on<SolicitarDomicilioEvent>((event, emit) async {
      final title =
          "recibira_n_paquetes".tr(args: [event.disponibles.length.toString()]);
      var paquetes = await domicilioDialog(event.context, title,
          "solicitar_domicilio".tr(), "cancelar".tr(), event.disponibles);
      if (paquetes.isEmpty) {
        return;
      }

      emit(DashboardLoadingState());
      var result = await _courierService.solicitaDomicilio(paquetes);
      emit(DashboardFinishedState(
          withErrors: result.isNotEmpty, errorMessage: result));
    });

    on<LoadApiEvent>((event, emit) async {
      final generation = ++_loadGeneration;
      try {
        emit(DashboardLoadingState());
        final empresa =
            await _courierService.getEmpresa(ignoreCache: event.forceRefresh);
        final banners = await _courierService.getBanners();
        final mensajes =
            await _courierService.getMensajes(ignoreCache: event.forceRefresh);
        final recepciones =
            await _courierService.getRecepciones(event.forceRefresh);
        final puntos = empresa.hasPointsModule
            ? await _courierService.getPuntos()
            : Puntos.empty();
        final moreInfoText =
            await _courierService.empresaOptionValue("MoreInfoText");
        final moreInfoUrl =
            await _courierService.empresaOptionValue("MoreInfoUrl");
        final reclamoUrl =
            await _courierService.empresaOptionValue("ReclamoUrl");
        final referirUrl =
            await _courierService.empresaOptionValue("ReferirUrl");
        final recepcionesCount = recepciones.length;

        final retenidosCount =
            recepciones.where((element) => element.retenido == true).length;

        var disponibles =
            recepciones.where((element) => element.disponible == true).toList();
        final disponiblesCount = disponibles.length;
        final montoTotal = disponibles.map((e) => e.montoTotal()).toList().sum;

        if (generation != _loadGeneration) {
          return;
        }
        emit(DashboardLoadedState(
            empresa: empresa,
            banners: banners,
            recepciones: recepciones,
            recepcionesCount: recepcionesCount,
            disponiblesCount: disponiblesCount,
            montoTotal: montoTotal,
            retenidosCount: retenidosCount,
            puntos: puntos,
            mensajes: mensajes,
            moreInfoText: moreInfoText,
            moreInfoUrl: moreInfoUrl,
            reclamoUrl: reclamoUrl,
            referirUrl: referirUrl));
      } catch (e) {
        if (generation != _loadGeneration) {
          return;
        }
        emit(DashboardFinishedState(
            withErrors: true, errorMessage: "error_favor_reintentar".tr()));
      }
    });
  }
}
