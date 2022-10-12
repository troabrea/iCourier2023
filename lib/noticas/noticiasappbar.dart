import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/courierService.dart';

class NoticiasAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NoticiasAppBar({Key? key, this.showBackButton = false}) : super(key: key);
  final bool showBackButton;
  @override
  Widget build(BuildContext context) {
    return showBackButton ? AppBar(
      title: const Text("Noticias"),
      automaticallyImplyLeading: false,
      leading: BackButton( color: Theme.of(context).appBarTheme.iconTheme?.color)) :
          AppBar(
          title: const Text("Noticias"),
      actions: [IconButton(
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
