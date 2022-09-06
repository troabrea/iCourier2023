import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:iCourier/services/app_events.dart';
import 'package:iCourier/services/connectivityService.dart';
import 'package:iCourier/sucursales/sucursales.dart';
import 'package:navbar_router/navbar_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version_check/version_check.dart';
import 'dart:math' as math;
import 'package:event/event.dart' as event;

import 'adicional/adicional.dart';
import 'calculadora/calculadora.dart';
import 'courier/courier.dart';
import 'noticas/noticias.dart';

late AndroidNotificationChannel channel;
bool isFlutterLocalNotificationsInitialized = false;
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

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
          icon: 'ic_push_icon',
        ),
      ),
    );
  }
}

class MainAppShell extends StatefulWidget {
  const MainAppShell({Key? key}) : super(key: key);

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell>  {

  final _connectivityService = ConnectivityService();

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

    // Check Connectivity
    var wasLost = false;
    _connectivityService.connectivityStream.stream.listen((event) {
      if (event == ConnectivityResult.none) {
        wasLost = true;
        ScaffoldMessenger.of(context).showMaterialBanner(
            MaterialBanner( backgroundColor: Theme.of(context).errorColor, content: Text("Se ha perdido la conexión a internet, algunas funciones de la aplicación no estarán disponibles.", style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.white)), actions: [TextButton(onPressed: () {
              ScaffoldMessenger.of(context)
                  .hideCurrentMaterialBanner();
            }, child: const Text("Aceptar"))])
        );
      } else {
        if(wasLost) {
          wasLost = false;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Conexión a internet restaurada!")));
        }
      }});

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
    return Scaffold(
      resizeToAvoidBottomInset: false,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: !showFab ? null : Transform.translate(offset: const Offset(0, -4),
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
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor, // Theme.of(context).primaryColor,
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
    );  //showFab ? buildScaffoldWithFab(size, context) : buildScaffoldNoFab(size, context);
  }
}