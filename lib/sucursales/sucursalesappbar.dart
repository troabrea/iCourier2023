import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';

class SucursalesAppBar extends StatefulWidget implements PreferredSizeWidget {
  const SucursalesAppBar({Key? key}) : super(key: key);

  @override
  State<SucursalesAppBar> createState() => _SucursalesAppBarAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _SucursalesAppBarAppBarState extends State<SucursalesAppBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text("Sucursales"),
    );
  }
}
