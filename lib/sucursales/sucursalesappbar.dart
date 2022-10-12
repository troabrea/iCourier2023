import 'package:app_bar_with_search_switch/app_bar_with_search_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/courierService.dart';

class SucursalesAppBar extends StatefulWidget implements PreferredSizeWidget {
  const SucursalesAppBar({Key? key}) : super(key: key);

  @override
  State<SucursalesAppBar> createState() => _SucursalesAppBarAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _SucursalesAppBarAppBarState extends State<SucursalesAppBar> {
  String searchText = "";
  @override
  Widget build(BuildContext context) {

    return AppBarWithSearchSwitch(
      fieldHintText: 'Buscar',
      keepAppBarColors: false,
      onChanged: (text) {
        setState(() {
          searchText = text;
        });
      },
      // onSubmitted: (text) {
      //   searchText.value = text;
      // },
      appBarBuilder: (context) {
        return AppBar(
          title: const Text("Sucursales"),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: Icon(Icons.whatsapp_rounded,
                color: Theme.of(context).appBarTheme.foregroundColor,
              ),
              onPressed: ()  {
                chatWithSucursal();
              },
            ),
            IconButton(onPressed: AppBarWithSearchSwitch.of(context)?.startSearch, icon: Icon(Icons.search, color: Theme.of(context).appBarTheme.foregroundColor,)),
          ],
        );
      },
    );

    return AppBar(
      title: const Text("Sucursales"),
    );
  }

  Future<void> chatWithSucursal() async {
    var userProfile = await GetIt.I<CourierService>().getUserProfile();
    var whatsApp = userProfile.whatsappSucursal;
    if (whatsApp.isNotEmpty) {
      var _url = Uri.parse("whatsapp://send?phone=$whatsApp");
      if (!await launchUrl(_url)) {
        throw 'Could not launch $_url';
      }
    }
  }

}
