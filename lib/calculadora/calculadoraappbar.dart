import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/courier_service.dart';

class CalculadoraAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CalculadoraAppBar({Key? key}) : super(key: key);

  @override
  State<CalculadoraAppBar> createState() => _CalculadoraAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CalculadoraAppBarState extends State<CalculadoraAppBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text("Calculadora"),
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
