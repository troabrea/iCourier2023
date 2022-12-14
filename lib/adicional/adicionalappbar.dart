import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/courier_service.dart';

class AdicionalPageAppBar extends StatefulWidget implements PreferredSizeWidget {
  const AdicionalPageAppBar({Key? key}) : super(key: key);

  @override
  State<AdicionalPageAppBar> createState() => _AdicionalPageAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _AdicionalPageAppBarState extends State<AdicionalPageAppBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text("Información Adicional"),
      actions: [
        IconButton(
          icon: Icon(Icons.whatsapp_rounded,
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
          onPressed: ()  {
            chatWithSucursal();
          },
        ),
      ],
    );
  }
  Future<void> chatWithSucursal() async {
    var userProfile = await GetIt.I<CourierService>().getUserProfile();
    var whatsApp = userProfile.whatsappSucursal; // (await GetIt.I<CourierService>().getEmpresa()).telefonoVentas;
    if (whatsApp.isNotEmpty) {
      var _url = Uri.parse("whatsapp://send?phone=$whatsApp");
      if (!await launchUrl(_url)) {
        throw 'Could not launch $_url';
      }
    }
  }
}