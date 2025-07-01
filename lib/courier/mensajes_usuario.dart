import 'dart:convert';
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/services/app_events.dart';
import 'package:icourier/services/model/mensaje.dart';
import 'package:url_launcher/url_launcher.dart';
import '../apps/appinfo.dart';
import 'package:image_picker/image_picker.dart';


import '../services/courier_service.dart';
import '../services/model/login_model.dart';

class MensajesUsuario extends StatefulWidget {
  final appInfo = GetIt.I<AppInfo>();

  MensajesUsuario({super.key});

  @override
  State<MensajesUsuario> createState() => _MensajesUsuarioState();
}

class _MensajesUsuarioState extends State<MensajesUsuario> {
  bool isBusy = false;
  String profileUrl = "";
  final mensajes = <Mensaje>[].toList();

  //NavbarNotifier.hideBottomNavBar = true;
  _MensajesUsuarioState();

  @override
  void initState() {
    loadData();
    super.initState();
  }

  Future<void> loadData() async {
    var list = await GetIt.I<CourierService>().getMensajes();
    mensajes.clear();
    mensajes.addAll(list);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
          decoration: ShapeDecoration(
              color: Theme.of(context).appBarTheme.backgroundColor,
              shape: const RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20)))),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                    child: AutoSizeText("sus_mensajes".tr(),
                        maxLines: 1,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context)
                                .appBarTheme
                                .foregroundColor))),
              ),
            ],
          )),
      SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: ListView.separated(
          separatorBuilder: (ctx,idx) => const SizedBox(height: 8,),
          itemBuilder: (ctx, idx) => Card(
            surfaceTintColor: mensajes[idx].read ? null : Colors.red,
            child: ListTile(
              onTap: () { markAsRead(mensajes[idx]); },
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: AutoSizeText(mensajes[idx].titulo,maxLines: 2, style: Theme.of(context).textTheme.headlineMedium!.copyWith(fontSize: 16),)),
                  const SizedBox(width: 2,),
                  AutoSizeText(DateFormat("dd-MMM-yyyy").format(mensajes[idx].fecha), maxLines: 2, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(mensajes[idx].contenido, textAlign: TextAlign.justify),
              ),
            ),
          ),
          itemCount: mensajes.length,
        ),
      ),
      SafeArea(child: OutlinedButton(onPressed: () { markAllAsRead(); }, child: Text("todo_leido".tr())))
    ]);
  }

  Future markAsRead(Mensaje mensaje) async {
    setState(() {
      mensaje.read = true;
    });
    await GetIt.I<CourierService>().setMessagesRead( [mensaje.registroId].toList() );
  }
  Future markAllAsRead() async {
    await GetIt.I<CourierService>().setMessagesRead( mensajes.map((e) => e.registroId).toList() );
    setState(() {
      for (var mensaje in mensajes) {
        mensaje.read = true;
      }
    });
  }

}


