import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';

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
    );
  }
}
