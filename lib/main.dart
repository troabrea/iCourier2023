import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:navbar_router/navbar_router.dart';
import 'package:sampleapi/adicional/adicional.dart';
import 'package:sampleapi/noticas/noticias.dart';
import 'package:sampleapi/services/app_events.dart';
import 'package:sampleapi/services/courierService.dart';
import 'package:sampleapi/services/model/appstate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import 'package:version_check/version_check.dart';

import 'package:provider/provider.dart';

import 'package:sampleapi/sucursales/sucursales.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import 'apptheme.dart';
import 'calculadora/calculadora.dart';
import 'courier/courier.dart';

import 'package:event/event.dart' as event;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  showFlutterNotification(message);
}

late AndroidNotificationChannel channel;
bool isFlutterLocalNotificationsInitialized = false;
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

Future<void> setupFlutterNotifications() async {
  if (isFlutterLocalNotificationsInitialized) {
    return;
  }
  channel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'Notificaciones y Alertas', // title
    description:
    'Notifiaciones y alertas sobres sus paquetes e información importante.', // description
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

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (kDebugMode) {
    print('User granted permission: ${settings.authorizationStatus}');
  }

  //
  messaging.subscribeToTopic("DOMEX");

}

void showFlutterNotification(RemoteMessage message) {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;
  if (notification != null && android != null && !kIsWeb) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          // TODO add a proper drawable resource to android, for now using
          //      one that already exists in example app.
          icon: 'ic_push_icon',
        ),
      ),
    );
  }
}


Future<void> main()  async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await setupFlutterNotifications();
  // Set the background messaging handler early on, as a named top-level function
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  if (!kIsWeb) {
    await setupFlutterNotifications();
  }

  //final fcmToken = await FirebaseMessaging.instance.getToken();

  GetIt.I.registerSingleton<CourierService>(CourierService());
  GetIt.I.registerSingleton<event.Event<LoginChanged>>(event.Event<LoginChanged>());
  GetIt.I.registerSingleton<event.Event<LogoutRequested>>(event.Event<LogoutRequested>());
  GetIt.I.registerSingleton<event.Event<CourierRefreshRequested>>(event.Event<CourierRefreshRequested>());
  GetIt.I.registerSingleton<event.Event<ToogleBarEvent>>(event.Event<ToogleBarEvent>());
  GetIt.I.registerSingleton<event.Event<NoticiasDataRefreshRequested>>(event.Event<NoticiasDataRefreshRequested>());
  GetIt.I.registerSingleton<event.Event<SucursalesDataRefreshRequested>>(event.Event<SucursalesDataRefreshRequested>());

  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {

  const MyApp({Key? key}) : super(key: key);
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
        theme: getLightTheme(), // getAppTheme(),
        darkTheme: getDarkTheme(),
        themeMode: ThemeMode.system,
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AppStateModel>(
              create: (context) => AppStateModel(),
            ),
          ],
          child: MultiRepositoryProvider(providers: [
            RepositoryProvider(
              create: (context) => GetIt.I<CourierService>(),
            ),
          ], child: const MainAppShell()),
        ));
  }
}

class MainAppShell extends StatefulWidget {
  const MainAppShell({Key? key}) : super(key: key);

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell>  {

  final _checker = VersionCheck(
    showUpdateDialog: (context, versionCheck) async {
      if (versionCheck.storeUrl == null) return;
      if (versionCheck.packageVersion == null) return;
      if (versionCheck.storeVersion == null) return;
      if (versionCheck.packageVersion == versionCheck.storeVersion) return;

      bool shouldUpdate = false;

      final versionNumbersA =
      versionCheck.packageVersion!.split(".").map((e) => int.tryParse(e) ?? 0).toList();
      final versionNumbersB =
      versionCheck.storeVersion!.split(".").map((e) => int.tryParse(e) ?? 0).toList();

      final int versionASize = versionNumbersA.length;
      final int versionBSize = versionNumbersB.length;
      int maxSize = math.max(versionASize, versionBSize);

      for (int i = 0; i < maxSize; i++) {
        if ((i < versionASize ? versionNumbersA[i] : 0) >
            (i < versionBSize ? versionNumbersB[i] : 0)) {
          shouldUpdate = false;
        } else if ((i < versionASize ? versionNumbersA[i] : 0) <
            (i < versionBSize ? versionNumbersB[i] : 0)) {
          shouldUpdate = true;
        }
        if(i == 0 && shouldUpdate == false) break;
      }

      if(shouldUpdate) {
        await showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return WillPopScope(
                child: AlertDialog(
                  title: const Text('Actualización Disponible!'),
                  content: Text('Existe una nueva versión (${versionCheck.storeVersion!}) más reciente que su versión actual (${versionCheck.packageVersion}), desea actualizar?'),
                  actions: [
                    TextButton(
                      child: const Text('Quizas Despues'),
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true).pop();
                      },
                    ),
                    TextButton(
                      child: const Text('Actualizar'),
                      onPressed: () async {
                        await launchUrl(Uri.parse(versionCheck.storeUrl!));
                        Navigator.of(context, rootNavigator: true).pop();
                      },
                    ),
                  ],
                ),
                onWillPop: () => Future.value(true));
          },
        );

      }

    }
  );


  @override
  void initState() {
    super.initState();
    // Push Notifications
    // Foreground State
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showFlutterNotification(message);
    });
    // Background State
    FirebaseMessaging.onMessageOpenedApp.listen((value) => {
      if(value.notification?.body != null && value.notification?.title != null){
        showDialog(
          context: context,
          builder: (BuildContext context) =>
              AlertDialog(
                title: Text(value.notification!.title!,
                    style: Theme
                        .of(context)
                        .textTheme
                        .titleLarge),
                content: Text(
                    value.notification!.body!),
              ),
        )
      }
    });
    // Terminated State
    FirebaseMessaging.instance.getInitialMessage().then((value) => {
      if(value?.notification?.body != null && value?.notification?.title != null){
          showDialog(
          context: context,
          builder: (BuildContext context) =>
              AlertDialog(
                title: Text(value!.notification!.title!,
                    style: Theme
                        .of(context)
                        .textTheme
                        .titleLarge),
                content: Text(
                    value.notification!.body!),
              ),
        )
      }
    });

    // Check for new version of app
    checkVersion();
  }

  void checkVersion() async {
    await _checker.checkVersion(context);
  }

  bool showFab = true;

  _MainAppShellState() {
    GetIt.I<event.Event<ToogleBarEvent>>().subscribe((args)  {
      showFab = args?.show ?? true;
      NavbarNotifier.hideBottomNavBar = !showFab;
      setState(() {});
    });
  }

  final int _index = 0;

  int currentIndex = 0;

  List<NavbarItem> items = const [
    NavbarItem(Icons.feed_outlined, 'Noticias'),
    NavbarItem(Icons.place_outlined, 'Sucursales'),
    NavbarItem(Icons.home , 'Inicio'), // Faked icon to create empty space
    NavbarItem(Icons.calculate_outlined, 'Calculadora'),
    NavbarItem(Icons.info_outline, 'Más'),
  ];

  final Map<int, Map<String, Widget>> _routes =  {
    0: {
      '/': const NoticiasPage(),
      // '/noticiadetalle': const NoticiaDetallePage(),
    },
    1: {
      '/': const SucursalesPage(),
    },
    2: {
      '/': const CourierPage(),
    },
    3: {
      '/': const CalculadoraPage(),
    },
    4: {
      '/': const AdicionalInfoPage(),
      // '/servicios': const ServiciosPage(),
      // '/preguntas': const PreguntasPage(),
    },
  };

  void showSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 600),
        margin: EdgeInsets.only(
            bottom: kBottomNavigationBarHeight, right: 2, left: 2),
        content: Text('Presione el boton nuevamente para salir de la aplicación.'),
      ),
    );
  }

  void hideSnackBar() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  DateTime oldTime = DateTime.now();
  DateTime newTime = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return showFab ? buildScaffoldWithFab(size, context) : buildScaffoldNoFab(size, context);
  }

  Scaffold buildScaffoldWithFab(Size size, BuildContext context) {
    return Scaffold(
    resizeToAvoidBottomInset: false,
    floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    floatingActionButton: Transform.translate(offset: const Offset(0, -4),
      child: SizedBox(height: 50, width: 50,
        child: FloatingActionButton(
          elevation: 0,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30),
          side: BorderSide(color: Theme.of(context).primaryColorDark, width: 2)),
          child: Padding(
            padding: const EdgeInsets.all(3.0),
            child: Image.asset("images/icon.png", height: currentIndex == 2 ? 35 : 25, width: currentIndex == 2 ? 35 : 25,),
          )
              ,
          onPressed: () {
            // Programmatically toggle the Navbar visibility
            setState(() {
              if(NavbarNotifier.currentIndex != 2) {
                NavbarNotifier.index = 2;
                setState(() {
                  currentIndex = 2;
                });
              } else {
                NavbarNotifier.popAllRoutes(2);
              }
            });
          },
        ),
      ),
    ),
    body: NavbarRouter(
      errorBuilder: (context) {
        return const Center(child: Text('Error 404'));
      },
      initialIndex: _index,
      isDesktop: size.width > 600 ? true : false,
      onBackButtonPressed: (isExitingApp) {
        if (isExitingApp) {
          newTime = DateTime.now();
          int difference = newTime.difference(oldTime).inMilliseconds;
          oldTime = newTime;
          if (difference < 1000) {
            hideSnackBar();
            return isExitingApp;
          } else {
            showSnackBar();
            return false;
          }
        } else {
          return isExitingApp;
        }
      },
      destinationAnimationCurve: Curves.fastOutSlowIn,
      destinationAnimationDuration: 400,
      decoration: NavbarDecoration(
          backgroundColor: Theme.of(context).primaryColor,
          selectedLabelTextStyle: Theme.of(context).navigationBarTheme.labelTextStyle!.resolve(<MaterialState>{ MaterialState.selected }),
          showUnselectedLabels: false,
          showSelectedLabels: false,
          enableFeedback: true,
          unselectedIconTheme: IconThemeData(color: Theme.of(context).appBarTheme.foregroundColor!.withOpacity(0.80),size: 25),
          selectedIconTheme: IconThemeData(color: Theme.of(context).appBarTheme.foregroundColor, size: 30),
          isExtended: size.width > 800 ? true : false,
          navbarType: BottomNavigationBarType.fixed),
      onChanged: (x) {
        if(x == 0) {
          GetIt.I<event.Event<NoticiasDataRefreshRequested>>().broadcast(NoticiasDataRefreshRequested());
        }
        if(x == 1) {
          GetIt.I<event.Event<SucursalesDataRefreshRequested>>().broadcast(SucursalesDataRefreshRequested());
        }
        setState(() {
          currentIndex = x;
        });
      },
      backButtonBehavior: BackButtonBehavior.rememberHistory,
      destinations: [
        for (int i = 0; i < items.length; i++)
          DestinationRouter(
            navbarItem: items[i],
            destinations: [
              for (int j = 0; j < _routes[i]!.keys.length; j++)
                Destination(
                  route: _routes[i]!.keys.elementAt(j),
                  widget: _routes[i]!.values.elementAt(j),
                ),
            ],
            initialRoute: _routes[i]!.keys.first,
          ),
      ],
    ),
  );
  }

  Scaffold buildScaffoldNoFab(Size size, BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: NavbarRouter(
        errorBuilder: (context) {
          return const Center(child: Text('Error 404'));
        },
        initialIndex: _index,
        isDesktop: size.width > 600 ? true : false,
        onBackButtonPressed: (isExitingApp) {
          if (isExitingApp) {
            newTime = DateTime.now();
            int difference = newTime.difference(oldTime).inMilliseconds;
            oldTime = newTime;
            if (difference < 1000) {
              hideSnackBar();
              return isExitingApp;
            } else {
              showSnackBar();
              return false;
            }
          } else {
            return isExitingApp;
          }
        },
        destinationAnimationCurve: Curves.fastOutSlowIn,
        destinationAnimationDuration: 400,
        decoration: NavbarDecoration(
            backgroundColor: Theme.of(context).primaryColor,
            selectedLabelTextStyle: Theme.of(context).navigationBarTheme.labelTextStyle!.resolve(<MaterialState>{ MaterialState.selected }),
            showUnselectedLabels: false,
            showSelectedLabels: false,
            enableFeedback: true,
            unselectedIconTheme: IconThemeData(color: Theme.of(context).appBarTheme.foregroundColor!.withOpacity(0.80),size: 25),
            selectedIconTheme: IconThemeData(color: Theme.of(context).appBarTheme.foregroundColor, size: 30),
            isExtended: size.width > 800 ? true : false,
            navbarType: BottomNavigationBarType.fixed),
        backButtonBehavior: BackButtonBehavior.rememberHistory,
        destinations: [
          for (int i = 0; i < items.length; i++)
            DestinationRouter(
              navbarItem: items[i],
              destinations: [
                for (int j = 0; j < _routes[i]!.keys.length; j++)
                  Destination(
                    route: _routes[i]!.keys.elementAt(j),
                    widget: _routes[i]!.values.elementAt(j),
                  ),
              ],
              initialRoute: _routes[i]!.keys.first,
            ),
        ],
      ),
    );
  }

}

