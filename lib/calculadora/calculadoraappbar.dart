import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/services/model/login_model.dart';
import 'package:url_launcher/url_launcher.dart';

import '../apps/appinfo.dart';
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
  bool hasChat = false;
  @override void initState() {
    super.initState();
    _configureWithProfile();
  }

  Future<void> _configureWithProfile() async {
    userProfile = await GetIt.I<CourierService>().getUserProfile();
    setState(() {
      hasWhatsApp = userProfile.whatsappSucursal.isNotEmpty;
      hasChat = !hasWhatsApp && userProfile.chatUrl.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text("calculadora".tr()),
      actions: [
        if(hasWhatsApp)
        IconButton(
          icon: FaIcon(FontAwesomeIcons.whatsapp,
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
          onPressed: ()  {
            chatWithSucursal();
          },
        ),
        if(hasChat)
          IconButton(
            icon: Icon(Icons.chat,
              color: Theme.of(context).appBarTheme.foregroundColor,
            ),
            onPressed: () async {
              launchUrl(Uri.parse(userProfile.chatUrl));
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
