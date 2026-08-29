import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:event/event.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../design_system/brand_foundations.dart';
import '../design_system/overlay_components.dart';
import '../noticas/emerging_news_coordinator.dart';
import '../noticas/emerging_news_dialog.dart';
import '../services/app_events.dart';
import '../services/courier_service.dart';
import '../services/notification_service.dart';
import '../surveys/survey_launcher.dart';
import '../surveys/survey_prompt_coordinator.dart';
import '../surveys/survey_prompt_cue.dart';
import '../theme/brand_config.dart';
import '../theme/brand_tokens.dart';
import 'app_routes.dart';

/// Owns application-wide integrations that previously lived in the old tab UI.
class AppRuntimeHost extends StatefulWidget {
  const AppRuntimeHost({
    super.key,
    required this.child,
    required this.preferences,
    this.foregroundMessages,
    this.openedMessages,
    this.loadInitialMessage,
    this.navigatorKey,
    this.router,
    this.emergingNewsCoordinator,
    this.emergingNewsImagePreloader = preloadEmergingNewsImage,
  });

  final Widget child;
  final SharedPreferences preferences;
  final Stream<RemoteMessage>? foregroundMessages;
  final Stream<RemoteMessage>? openedMessages;
  final Future<RemoteMessage?> Function()? loadInitialMessage;
  final GlobalKey<NavigatorState>? navigatorKey;
  final GoRouter? router;
  final EmergingNewsCoordinator? emergingNewsCoordinator;
  final EmergingNewsImagePreloader emergingNewsImagePreloader;

  @override
  State<AppRuntimeHost> createState() => _AppRuntimeHostState();
}

class _AppRuntimeHostState extends State<AppRuntimeHost>
    with WidgetsBindingObserver {
  final _connectivity = Connectivity();
  final _quickActions = const QuickActions();
  late final AppDeepLinkParser _linkParser;
  late final SurveyPromptCoordinator _surveyPromptCoordinator;
  late final SurveyLauncher _surveyLauncher;
  late final EmergingNewsCoordinator _emergingNewsCoordinator;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _openedMessageSubscription;
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _surveyCue;
  bool _connectionWasLost = false;
  bool _isOpeningSurvey = false;
  bool _isShowingEmergingNews = false;
  bool _isCheckingRuntimePrompts = false;

  @override
  void initState() {
    super.initState();
    _linkParser = AppDeepLinkParser(
      urlScheme: GetIt.I<BrandConfig>().urlScheme,
    );
    final surveyStore = SharedPreferencesSurveyPromptStore(widget.preferences);
    _surveyPromptCoordinator = SurveyPromptCoordinator(
      loadCompany: () => GetIt.I<CourierService>().getEmpresa(
        forceFirstTime: true,
      ),
      store: surveyStore,
    );
    _surveyLauncher = SurveyLauncher(store: surveyStore);
    final courierService = GetIt.I<CourierService>();
    _emergingNewsCoordinator = widget.emergingNewsCoordinator ??
        EmergingNewsCoordinator(
          loadCompany: () => courierService.getEmpresa(forceFirstTime: true),
          loadNews: () => courierService.getNoticias(true),
          store: SharedPreferencesEmergingNewsSeenStore(widget.preferences),
        );
    final initialMessage = widget.loadInitialMessage?.call() ??
        FirebaseMessaging.instance.getInitialMessage();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_handleInitialMessage(initialMessage));
    });
    _configureQuickActions();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
    _foregroundMessageSubscription =
        (widget.foregroundMessages ?? FirebaseMessaging.onMessage)
            .listen(_onForegroundMessage);
    _openedMessageSubscription =
        (widget.openedMessages ?? FirebaseMessaging.onMessageOpenedApp)
            .listen((message) => unawaited(_openMessage(message)));
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
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    _foregroundMessageSubscription?.cancel();
    _openedMessageSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkForRuntimePrompts());
      unawaited(_refreshMessageHistory());
    }
  }

  Future<void> _checkForRuntimePrompts() async {
    if (!mounted || _isShowingEmergingNews || _isCheckingRuntimePrompts) {
      return;
    }
    _isCheckingRuntimePrompts = true;
    try {
      if (await _showEmergingNewsIfAvailable()) {
        return;
      }
      await _checkForSurvey();
    } finally {
      _isCheckingRuntimePrompts = false;
    }
  }

  Future<void> _handleInitialMessage(
    Future<RemoteMessage?> initialMessage,
  ) async {
    RemoteMessage? message;
    try {
      message = await initialMessage;
    } on Exception catch (error) {
      debugPrint('Initial push lookup failed: $error');
    }
    if (!mounted) {
      return;
    }
    if (message != null) {
      await _openMessage(message);
      return;
    }
    await _checkForRuntimePrompts();
  }

  Future<bool> _showEmergingNewsIfAvailable() async {
    EmergingNewsAnnouncement? announcement;
    try {
      announcement = await _emergingNewsCoordinator.findAnnouncement();
    } on Exception catch (error) {
      debugPrint('Emerging news availability check failed: $error');
      return false;
    }
    if (!mounted || announcement == null) {
      return false;
    }

    final presentationContext = widget.navigatorKey?.currentContext ??
        Navigator.maybeOf(context)?.context;
    if (presentationContext == null || !presentationContext.mounted) {
      return false;
    }
    final imageReady = await widget.emergingNewsImagePreloader(
      presentationContext,
      announcement.imageUrl,
    );
    if (!mounted || !presentationContext.mounted || !imageReady) {
      return false;
    }

    try {
      await _emergingNewsCoordinator.markShown(announcement);
    } on Exception catch (error) {
      debugPrint('Emerging news persistence failed: $error');
      return false;
    }
    if (!mounted || !presentationContext.mounted) {
      return false;
    }

    _isShowingEmergingNews = true;
    late final bool openNews;
    try {
      openNews = await showEmergingNewsDialog(
        presentationContext,
        announcement: announcement,
      );
    } finally {
      _isShowingEmergingNews = false;
    }
    if (!mounted || !openNews || announcement.news == null) {
      return true;
    }

    final news = announcement.news!;
    final location = AppRoutes.newsDetail(news.heroIdentity);
    final router = widget.router;
    if (router != null) {
      await router.push<void>(location, extra: news);
    } else if (presentationContext.mounted) {
      await presentationContext.push<void>(location, extra: news);
    }
    return true;
  }

  Future<void> _checkForSurvey() async {
    if (!mounted || _surveyCue != null || _isOpeningSurvey) {
      return;
    }
    try {
      final invitation = await _surveyPromptCoordinator.findInvitation();
      if (!mounted || invitation == null || _surveyCue != null) {
        return;
      }
      _showSurveyCue(invitation);
    } on Exception catch (error) {
      debugPrint('Survey availability check failed: $error');
    }
  }

  void _showSurveyCue(SurveyInvitation invitation) {
    final messenger = ScaffoldMessenger.of(context);
    var answered = false;
    late final ScaffoldFeatureController<SnackBar, SnackBarClosedReason>
        controller;

    void closeCue(SnackBarClosedReason reason) {
      messenger.hideCurrentSnackBar(reason: reason);
    }

    controller = messenger.showSnackBar(
      buildSurveyPromptSnackBar(
        context,
        onPostpone: () => closeCue(SnackBarClosedReason.dismiss),
        onAnswer: () {
          answered = true;
          closeCue(SnackBarClosedReason.action);
          unawaited(_openSurvey(invitation));
        },
      ),
    );
    _surveyCue = controller;
    unawaited(
      controller.closed.then((reason) async {
        if (!answered && reason != SnackBarClosedReason.remove) {
          await _surveyPromptCoordinator.postpone(invitation);
        }
        if (identical(_surveyCue, controller)) {
          _surveyCue = null;
        }
      }),
    );
  }

  Future<void> _openSurvey(SurveyInvitation invitation) async {
    _isOpeningSurvey = true;
    var opened = false;
    try {
      opened = await _surveyLauncher.open(invitation);
    } on Exception catch (error) {
      debugPrint('Survey launch failed: $error');
    } finally {
      _isOpeningSurvey = false;
    }
    if (opened || !mounted) {
      return;
    }
    await _surveyPromptCoordinator.postpone(invitation);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('encuesta_no_abierta'.tr())),
    );
  }

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

  Future<void> _openMessage(RemoteMessage message) async {
    if (!mounted) {
      return;
    }
    unawaited(_refreshMessageHistory());
    final rawLink = message.data['link']?.toString();
    final destination = rawLink == null ? null : _linkParser.parse(rawLink);
    if (destination != null) {
      final router = widget.router;
      if (router != null) {
        router.go(destination);
      } else {
        context.go(destination);
      }
      return;
    }
    final content = notificationContentFor(message);
    if (content == null) {
      return;
    }
    final presentationContext = widget.navigatorKey?.currentContext ??
        Navigator.maybeOf(context)?.context;
    if (presentationContext == null) {
      return;
    }
    await showBrandSheet<void>(
      presentationContext,
      child: BrandSheet(
        title: content.title,
        subtitle: content.body,
        children: [
          BrandPrimaryButton(
            label: 'aceptar'.tr(),
            onPressed: () => Navigator.of(presentationContext).pop(),
          ),
        ],
      ),
    );
  }

  void _onForegroundMessage(RemoteMessage message) {
    showFlutterNotification(message);
    unawaited(_refreshMessageHistory());
  }

  Future<void> _refreshMessageHistory() async {
    try {
      await GetIt.I<CourierService>().getMensajes(ignoreCache: true);
    } on Exception {
      // The push remains readable even if the history endpoint is unavailable.
    }
  }

  void _onConnectivityChanged(ConnectivityResult result) {
    if (!mounted) {
      return;
    }
    final tokens = context.brand;
    final messenger = ScaffoldMessenger.of(context);
    if (result == ConnectivityResult.none) {
      _connectionWasLost = true;
      messenger.showMaterialBanner(
        MaterialBanner(
          backgroundColor: tokens.danger,
          contentTextStyle: tokens.body(
            13,
            color: tokens.onAccent(tokens.danger),
          ),
          content: Text('no_internet'.tr()),
          actions: [
            IconButton(
              onPressed: messenger.hideCurrentMaterialBanner,
              icon: Icon(
                Icons.close,
                color: tokens.onAccent(tokens.danger),
              ),
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
