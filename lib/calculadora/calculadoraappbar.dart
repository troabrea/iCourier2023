import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/services/model/login_model.dart';
import 'package:url_launcher/url_launcher.dart';

import '../appinfo.dart';
import '../services/courier_service.dart';

class CalculadoraAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CalculadoraAppBar({Key? key}) : super(key: key);
  @override
  State<CalculadoraAppBar> createState() => _CalculadoraAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CalculadoraAppBarState extends State<CalculadoraAppBar> {
  late UserProfile userProfile;
  bool hasWhatsApp = false;
  @override void initState() {
    super.initState();
    _configureWithProfile();
  }

  Future<void> _configureWithProfile() async {
    userProfile = await GetIt.I<CourierService>().getUserProfile();
    setState(() {
      hasWhatsApp = userProfile.whatsappSucursal.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text("Calculadora"),
      actions: [
        if(hasWhatsApp)
        IconButton(
          icon: Icon(Icons.chat,
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
    var whatsApp = userProfile.whatsappSucursal; // (await GetIt.I<CourierService>().getEmpresa()).telefonoVentas;
    if (whatsApp.isNotEmpty) {
      var _url = Uri.parse("whatsapp://send?phone=$whatsApp");
      if (!await launchUrl(_url)) {
        throw 'Could not launch $_url';
      }
    }
  }
}
