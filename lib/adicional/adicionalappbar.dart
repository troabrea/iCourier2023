import 'package:flutter/material.dart';

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
    );
  }
}