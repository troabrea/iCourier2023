import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design_system/core_components.dart';
import '../theme/brand_config.dart';

class BrandNavigationShell extends StatelessWidget {
  const BrandNavigationShell({
    super.key,
    required this.navigationShell,
    required this.config,
  });

  final StatefulNavigationShell navigationShell;
  final BrandConfig config;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BrandTabBar(
        modules: config.navigation.tabs,
        index: navigationShell.currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
