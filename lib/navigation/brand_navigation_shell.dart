import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../asistente/assistant_action.dart';
import '../design_system/core_components.dart';
import '../services/courier_service.dart';
import '../theme/brand_config.dart';
import 'router_session.dart';

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
      bottomNavigationBar: _navigationBar(),
    );
  }

  Widget _navigationBar() {
    final session =
        GetIt.I.isRegistered<RouterSession>() ? GetIt.I<RouterSession>() : null;
    final courier = GetIt.I.isRegistered<CourierService>()
        ? GetIt.I<CourierService>()
        : null;

    Widget tabBar({Widget? trailing}) => BrandTabBar(
          modules: config.navigation.tabs,
          index: navigationShell.currentIndex,
          logoMark: config.assets.logoMark,
          trailing: trailing,
          onTap: (index) {
            unawaited(onTabSelected(index));
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
        );

    if (session == null || courier == null) {
      return tabBar();
    }
    return ListenableBuilder(
      listenable: Listenable.merge([session, courier.assistantEnabled]),
      builder: (context, _) => tabBar(
        trailing: session.isLoggedIn && courier.assistantEnabled.value
            ? const BrandAssistantFloatingAction()
            : null,
      ),
    );
  }
}
