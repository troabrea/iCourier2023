import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';

class NoticiasAppBar extends StatefulWidget implements PreferredSizeWidget {
  const NoticiasAppBar({Key? key}) : super(key: key);

  @override
  State<NoticiasAppBar> createState() => _NoticiasAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _NoticiasAppBarState extends State<NoticiasAppBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text("Noticias"),
      automaticallyImplyLeading: true,
    );
  }
}
