import 'package:app_center_bundle_sdk/app_center_bundle_sdk.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get_it/get_it.dart';
import 'appinfo.dart';
import '../../services/app_events.dart';
import '../../services/courier_service.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import 'package:event/event.dart' as event;
import 'package:flutter_cache/flutter_cache.dart' as cache;
import 'main_app_shell.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  showFlutterNotification(message);
}

Future<void> setupFlutterNotifications(String pushDefaultTopic) async {
  if (isFlutterLocalNotificationsInitialized) {
    return;
  }
  channel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'Notificaciones y Alertas',
    'Notificaciones y alertas sobre sus paquetes e información importante.', // description
    importance: Importance.high,
  );

  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Create an Android Notification Channel.
  ///
  /// We use this channel in the `AndroidManifest.xml` file to override the
  /// default FCM channel to enable heads up notifications.
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  /// Update the iOS foreground notification presentation options to allow
  /// heads up notifications.
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  isFlutterLocalNotificationsInitialized = true;

  //

  FirebaseMessaging messaging = FirebaseMessaging.instance;
  //
  messaging.subscribeToTopic(pushDefaultTopic);
}

Future<void> mainShared(AppInfo _appInfo)  async {
  final AppInfo appInfo = _appInfo;
  var widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  String strValue = (await cache.load('lastSelectedTab',"")).toString();
  if(strValue.isNotEmpty) {
    var intValue = int.tryParse(strValue);
    if(intValue != null) {
      appInfo.defaultTab = intValue;
    }
  }


  await Firebase.initializeApp();
  await setupFlutterNotifications(appInfo.pushChannelTopic);

  // Set the background messaging handler early on, as a named top-level function
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  //final fcmToken = await FirebaseMessaging.instance.getToken();
  GetIt.I.registerSingleton<AppInfo>(appInfo);
  GetIt.I.registerSingleton<CourierService>(CourierService());
  GetIt.I.registerSingleton<event.Event<UserPrealertaRequested>>(event.Event<UserPrealertaRequested>());
  GetIt.I.registerSingleton<event.Event<LoginChanged>>(event.Event<LoginChanged>());
  GetIt.I.registerSingleton<event.Event<LogoutRequested>>(event.Event<LogoutRequested>());
  GetIt.I.registerSingleton<event.Event<CourierRefreshRequested>>(event.Event<CourierRefreshRequested>());
  GetIt.I.registerSingleton<event.Event<EmpresaRefreshFinished>>(event.Event<EmpresaRefreshFinished>());
  GetIt.I.registerSingleton<event.Event<ToogleBarEvent>>(event.Event<ToogleBarEvent>());
  GetIt.I.registerSingleton<event.Event<NoticiasDataRefreshRequested>>(event.Event<NoticiasDataRefreshRequested>());
  GetIt.I.registerSingleton<event.Event<SucursalesDataRefreshRequested>>(event.Event<SucursalesDataRefreshRequested>());
  GetIt.I.registerSingleton<event.Event<SessionExpired>>(event.Event<SessionExpired>());

  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  //final secret = Platform.isAndroid ? appInfo.androidAnalyticsAppId : appInfo.iphoneAnalyticsAppId;

  AppCenter.startAsync( appSecretIOS: appInfo.iphoneAnalyticsAppId, appSecretAndroid: _appInfo.androidAnalyticsAppId, enableCrashes: true, enableAnalytics: true,  );
  AppCenter.trackEventAsync("${appInfo.metricsPrefixKey}_INICIO_SESION");

  runApp(MyApp());
}

class MyApp extends StatelessWidget {



  final AppInfo appInfo = GetIt.I<AppInfo>();
  MyApp({Key? key}) : super(key: key);
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          FormBuilderLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        supportedLocales: const [Locale('es',''),] , //FormBuilderLocalizations.delegate.supportedLocales,
        title: 'iCourier',
        theme: appInfo.getLightTheme(), // getAppTheme(),
        darkTheme: appInfo.getDarkTheme(),
        themeMode: ThemeMode.system,
        home:const MainAppShell(),
      );
  }
}



