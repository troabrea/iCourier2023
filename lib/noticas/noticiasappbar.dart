import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/appinfo.dart';
import 'package:icourier/services/model/login_model.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/courier_service.dart';

class NoticiasAppBar extends StatefulWidget implements PreferredSizeWidget {
  NoticiasAppBar({Key? key, this.showBackButton = false}) : super(key: key);
  final bool showBackButton;

  @override
  State<NoticiasAppBar> createState() => _NoticiasAppBarState();

  @override
  // TODO: implement preferredSize
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _NoticiasAppBarState extends State<NoticiasAppBar> {
  late UserProfile userProfile;
  bool hasWhatsApp = false;

  @override
  void initState() {
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
    return widget.showBackButton ? AppBar(
      title: const Text("Noticias"),
      automaticallyImplyLeading: false,
      leading: BackButton( color: Theme.of(context).appBarTheme.iconTheme?.color)) :
          AppBar(
          title: const Text("Noticias"),
      actions: [
        if(hasWhatsApp)
        IconButton(
        icon: Icon(Icons.whatsapp_rounded,
          color: Theme.of(context).appBarTheme.foregroundColor,
        ),
        onPressed: ()  {
          chatWithSucursal();
        },
      ),],
      automaticallyImplyLeading: false);
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

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
