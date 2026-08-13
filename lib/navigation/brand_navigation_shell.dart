import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design_system/core_components.dart';
import '../theme/brand_config.dart';

class BrandNavigationShell extends StatelessWidget {
  const BrandNavigationShell({
    super.key,
    required this.navigationShell,
    required this.config,
    required this.onTabSelected,
  });

  final StatefulNavigationShell navigationShell;
  final BrandConfig config;
  final Future<void> Function(int index) onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BrandTabBar(
        modules: config.navigation.tabs,
        index: navigationShell.currentIndex,
        logoMark: config.assets.logoMark,
        onTap: (index) {
          unawaited(onTabSelected(index));
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
