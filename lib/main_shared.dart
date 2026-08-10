import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:icourier/helpers/appcenter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'apps/appinfo.dart';
import '../../services/app_events.dart';
import '../../services/courier_service.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import 'package:event/event.dart' as event;
import 'package:flutter_cache/flutter_cache.dart' as cache;
import 'services/notification_service.dart';
import 'navigation/app_router.dart';
import 'navigation/app_runtime_host.dart';
import 'navigation/router_session.dart';
import 'theme/brand_config.dart';
import 'theme/brand_config_loader.dart';
import 'theme/brand_theme.dart';
import 'widget/widget_state_store.dart';
import 'widget/widget_sync_coordinator.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  setupFlutterNotifications('');
  showFlutterNotification(message);
}

Future<void> setupFlutterNotifications(String pushDefaultTopic) async {
  if (notificationsInitialized) {
    return;
  }
  notificationChannel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'Notificaciones y Alertas',
    description:
        'Notificaciones y alertas sobre sus paquetes e información importante.', // description
    importance: Importance.high,
  );

  localNotifications = FlutterLocalNotificationsPlugin();

  /// Create an Android Notification Channel.
  ///
  /// We use this channel in the `AndroidManifest.xml` file to override the
  /// default FCM channel to enable heads up notifications.
  await localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(notificationChannel);

  initializeLocalNotifications('whatsapp_action_category');

  /// Update the iOS foreground notification presentation options to allow
  /// heads up notifications.
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  notificationsInitialized = true;

  //

  FirebaseMessaging messaging = FirebaseMessaging.instance;
  //
  if (pushDefaultTopic.isNotEmpty) {
    messaging.subscribeToTopic(pushDefaultTopic);
  }
}

Future<void> mainShared(AppInfo appInfo) async {
  WidgetsFlutterBinding.ensureInitialized();
  final brandConfig = await BrandConfigLoader.load(appInfo.brandSlug);

  // final config =
  // PostHogConfig('phc_OFUDsVNTdf1yk608hX82AT4QvPvVAiVMZcVFE4ypBVq');
  // config.debug = true;
  // config.captureApplicationLifecycleEvents = false;
  // config.host = 'https://us.i.posthog.com';
  // config.flushAt = 1;
  // await Posthog().setup(config);

  await EasyLocalization.ensureInitialized();
  // FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  String strValue = (await cache.load('lastSelectedTab', "")).toString();
  if (strValue.isNotEmpty) {
    var intValue = int.tryParse(strValue);
    if (intValue != null) {
      appInfo.defaultTab = intValue;
    }
  }
  final initiallyLoggedIn =
      (await cache.load('sessionId', '')).toString().isNotEmpty;
  final preferences = await SharedPreferences.getInstance();

  await Firebase.initializeApp(options: appInfo.appFirebaseOptions);

  await setupFlutterNotifications(appInfo.pushChannelTopic);
  await FirebaseMessaging.instance.getAPNSToken();
  FirebaseMessaging.instance.requestPermission();
  // Set the background messaging handler early on, as a named top-level function
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  //final fcmToken = await FirebaseMessaging.instance.getToken();
  GetIt.I.registerSingleton<AppInfo>(appInfo);
  GetIt.I.registerSingleton<BrandConfig>(brandConfig);
  GetIt.I.registerSingleton<CourierService>(CourierService());
  await GetIt.I<CourierService>().clearDataCache();
  GetIt.I.registerSingleton<event.Event<UnreadMessagesChanged>>(
      event.Event<UnreadMessagesChanged>());
  GetIt.I.registerSingleton<event.Event<UserPrealertaRequested>>(
      event.Event<UserPrealertaRequested>());
  GetIt.I.registerSingleton<event.Event<LoginChanged>>(
      event.Event<LoginChanged>());
  GetIt.I.registerSingleton<event.Event<LogoutRequested>>(
      event.Event<LogoutRequested>());
  GetIt.I.registerSingleton<event.Event<CourierRefreshRequested>>(
      event.Event<CourierRefreshRequested>());
  GetIt.I.registerSingleton<event.Event<EmpresaRefreshFinished>>(
      event.Event<EmpresaRefreshFinished>());
  GetIt.I.registerSingleton<event.Event<ToogleBarEvent>>(
      event.Event<ToogleBarEvent>());
  GetIt.I.registerSingleton<event.Event<NoticiasDataRefreshRequested>>(
      event.Event<NoticiasDataRefreshRequested>());
  GetIt.I.registerSingleton<event.Event<SucursalesDataRefreshRequested>>(
      event.Event<SucursalesDataRefreshRequested>());
  GetIt.I.registerSingleton<event.Event<SessionExpired>>(
      event.Event<SessionExpired>());
  GetIt.I.registerSingleton<event.Event<NotificarRetiroRequested>>(
      event.Event<NotificarRetiroRequested>());
  GetIt.I.registerSingleton<event.Event<AutoNotificarRetiroRequested>>(
      event.Event<AutoNotificarRetiroRequested>());

  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  //final secret = Platform.isAndroid ? appInfo.androidAnalyticsAppId : appInfo.iphoneAnalyticsAppId;

  AppCenter.startAsync(
    appSecretIOS: appInfo.iphoneAnalyticsAppId,
    appSecretAndroid: appInfo.androidAnalyticsAppId,
    enableCrashes: true,
    enableAnalytics: true,
  );
  AppCenter.trackEventAsync("${appInfo.metricsPrefixKey}_INICIO_SESION");

  Future<dynamic> appIntentHandler(MethodCall call) async {
    switch (call.method) {
      case 'notificar_retiro':
        GetIt.I<event.Event<AutoNotificarRetiroRequested>>().broadcast();
      // break;
      default:
        throw PlatformException(
          code: 'No implementado',
          details: 'El método ${call.method} no esta implementado.',
        );
    }
  }

  MethodChannel channel = const MethodChannel('icourier_app_intent_channel');
  channel.setMethodCallHandler(appIntentHandler);

  runApp(EasyLocalization(
      startLocale: Locale(appInfo.defaultLocale),
      supportedLocales: appInfo.additionalLocale.isEmpty
          ? [Locale(appInfo.defaultLocale)]
          : [
              Locale(appInfo.defaultLocale),
              Locale(appInfo.additionalLocale),
            ],
      fallbackLocale: const Locale('es'),
      useOnlyLangCode: true,
      path: 'translations',
      child: MyApp(
        initiallyLoggedIn: initiallyLoggedIn,
        preferences: preferences,
      )));
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    required this.initiallyLoggedIn,
    required this.preferences,
  });

  final bool initiallyLoggedIn;
  final SharedPreferences preferences;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final AppInfo appInfo = GetIt.I<AppInfo>();
  final BrandConfig brandConfig = GetIt.I<BrandConfig>();
  late final RouterSession routerSession;
  late final GoRouter router;
  late final WidgetSyncCoordinator widgetSyncCoordinator;

  @override
  void initState() {
    super.initState();
    routerSession = RouterSession(
      initiallyLoggedIn: widget.initiallyLoggedIn,
      loginChanges: GetIt.I<event.Event<LoginChanged>>(),
    );
    router = AppRouter.create(
      config: brandConfig,
      session: routerSession,
      preferences: widget.preferences,
    );
    WidgetsBinding.instance.addObserver(this);
    widgetSyncCoordinator = WidgetSyncCoordinator(
      config: brandConfig,
      courierService: GetIt.I<CourierService>(),
      store: const MethodChannelWidgetStateStore(),
      initialBrightness:
          WidgetsBinding.instance.platformDispatcher.platformBrightness,
    )..start(
        loginChanges: GetIt.I<event.Event<LoginChanged>>(),
        refreshRequests: GetIt.I<event.Event<CourierRefreshRequested>>(),
        accountRefreshes: GetIt.I<event.Event<EmpresaRefreshFinished>>(),
        sessionExpirations: GetIt.I<event.Event<SessionExpired>>(),
      );
  }

  @override
  void didChangePlatformBrightness() {
    widgetSyncCoordinator.updateBrightness(
      WidgetsBinding.instance.platformDispatcher.platformBrightness,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    router.dispose();
    routerSession.dispose();
    super.dispose();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // FlutterNativeSplash.remove();
    var delegates = context.localizationDelegates;
    delegates.addAll([
      FormBuilderLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate
    ]);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: delegates,
      supportedLocales: context
          .supportedLocales, //FormBuilderLocalizations.delegate.supportedLocales,
      locale: context.locale,
      title: brandConfig.name,
      theme: BrandTheme.light(brandConfig),
      darkTheme: BrandTheme.dark(brandConfig),
      themeMode: ThemeMode.system,
      routerConfig: router,
      builder: (context, child) => AppRuntimeHost(child: child!),
    );
  }
}
