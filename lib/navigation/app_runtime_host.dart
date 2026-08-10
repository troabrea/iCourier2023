import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:event/event.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_actions/quick_actions.dart';

import '../services/app_events.dart';
import '../services/notification_service.dart';
import '../theme/brand_config.dart';
import '../theme/brand_tokens.dart';
import 'app_routes.dart';

/// Owns application-wide integrations that previously lived in the old tab UI.
class AppRuntimeHost extends StatefulWidget {
  const AppRuntimeHost({super.key, required this.child});

  final Widget child;

  @override
  State<AppRuntimeHost> createState() => _AppRuntimeHostState();
}

class _AppRuntimeHostState extends State<AppRuntimeHost> {
  final _connectivity = Connectivity();
  final _quickActions = const QuickActions();
  late final AppDeepLinkParser _linkParser;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _openedMessageSubscription;
  bool _connectionWasLost = false;

  @override
  void initState() {
    super.initState();
    _linkParser = AppDeepLinkParser(
      urlScheme: GetIt.I<BrandConfig>().urlScheme,
    );
    _configureQuickActions();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
    _foregroundMessageSubscription =
        FirebaseMessaging.onMessage.listen(showFlutterNotification);
    _openedMessageSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen(_openMessage);
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _openMessage(message);
      }
    });
    GetIt.I<Event<SessionExpired>>().subscribe((event) {
      if (!mounted) {
        return;
      }
      GetIt.I<Event<LoginChanged>>().broadcast(LoginChanged(false, '', ''));
      context.go(AppRoutes.login);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('password_invalido'.tr())),
      );
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _foregroundMessageSubscription?.cancel();
    _openedMessageSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  Future<void> _configureQuickActions() async {
    await _quickActions.initialize((shortcut) {
      if (!mounted) {
        return;
      }
      final location = switch (shortcut) {
        'calcular_envio' => AppRoutes.calculator,
        'show_disponible' => AppRoutes.available,
        'crear_postalerta' => '${AppRoutes.receptions}?retenido=true',
        'crear_prealerta' => AppRoutes.prealert,
        _ => null,
      };
      if (location != null) {
        context.go(location);
      }
    });
    await _quickActions.setShortcutItems([
      ShortcutItem(
        type: 'calcular_envio',
        localizedTitle: 'calcular_envio'.tr(),
        icon: 'ic_launcher',
      ),
      ShortcutItem(
        type: 'crear_prealerta',
        localizedTitle: 'crear_pre_alerta'.tr(),
        icon: 'ic_launcher',
      ),
      ShortcutItem(
        type: 'show_disponible',
        localizedTitle: 'ver_disponibles'.tr(),
        icon: 'ic_launcher',
      ),
      ShortcutItem(
        type: 'crear_postalerta',
        localizedTitle: 'crear_post_alerta'.tr(),
        icon: 'ic_launcher',
      ),
    ]);
  }

  void _openMessage(RemoteMessage message) {
    if (!mounted) {
      return;
    }
    final rawLink = message.data['link']?.toString();
    final destination = rawLink == null ? null : _linkParser.parse(rawLink);
    if (destination != null) {
      context.go(destination);
      return;
    }
    final notification = message.notification;
    if (notification?.title == null || notification?.body == null) {
      return;
    }
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification!.title!),
        content: Text(notification.body!),
      ),
    );
  }

  void _onConnectivityChanged(ConnectivityResult result) {
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    if (result == ConnectivityResult.none) {
      _connectionWasLost = true;
      messenger.showMaterialBanner(
        MaterialBanner(
          backgroundColor: context.brand.danger,
          content: Text(
            'no_internet'.tr(),
            style: TextStyle(color: context.brand.onPrimary),
          ),
          actions: [
            IconButton(
              onPressed: messenger.hideCurrentMaterialBanner,
              icon: Icon(Icons.close, color: context.brand.onPrimary),
            ),
          ],
        ),
      );
      return;
    }
    if (_connectionWasLost) {
      _connectionWasLost = false;
      messenger.clearMaterialBanners();
      messenger.showSnackBar(SnackBar(content: Text('internet_ok'.tr())));
    }
  }
}
