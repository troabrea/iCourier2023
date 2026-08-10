import 'package:flutter/material.dart';

import '../design_system/core_components.dart';
import '../services/model/recepcion.dart';

/// Backwards-compatible adapter while callers migrate to [PackageCard].
class PaqueteTile extends StatelessWidget {
  const PaqueteTile({super.key, required this.recepcion, this.onTap});

  final Recepcion recepcion;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PackageCard(package: recepcion, onTap: onTap);
  }
}
