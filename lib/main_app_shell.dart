import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:event/event.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_version_checker/flutter_app_version_checker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/servicios/servicios.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'services/app_events.dart';
import 'services/courier_service.dart';
import 'sucursales/sucursales.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:version_check/version_check.dart';
import 'dart:math' as math;
import 'package:event/event.dart' as event;
import 'package:flutter_cache/flutter_cache.dart' as cache;

import 'adicional/adicional.dart';
import 'appinfo.dart';
import 'calculadora/calculadora.dart';
import 'courier/courier.dart';
import 'courier/courier_recepciones.dart';
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
          channelDescription:  channel.description,
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

class _MainAppShellState extends State<MainAppShell> {
  //final _connectivityService = ConnectivityService();
  final _connectivity = Connectivity();
  //late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  final appInfo = GetIt.I<AppInfo>();
  var connectivityWasLost = false;
  DateTime? connectivityWasLostAt;
  // final _checker =
  //     VersionCheck(showUpdateDialog: (context, versionCheck) async {
  //   if (versionCheck.storeUrl == null) return;
  //   if (versionCheck.packageVersion == null) return;
  //   if (versionCheck.storeVersion == null) return;
  //   if (versionCheck.packageVersion == versionCheck.storeVersion) return;
  //
  //   bool shouldUpdate = false;
  //
  //   final versionNumbersA = versionCheck.packageVersion!
  //       .split(".")
  //       .map((e) => int.tryParse(e) ?? 0)
  //       .toList();
  //   final versionNumbersB = versionCheck.storeVersion!
  //       .split(".")
  //       .map((e) => int.tryParse(e) ?? 0)
  //       .toList();
  //
  //   final int versionASize = versionNumbersA.length;
  //   final int versionBSize = versionNumbersB.length;
  //   int maxSize = math.max(versionASize, versionBSize);
  //
  //   for (int i = 0; i < maxSize; i++) {
  //     if ((i < versionASize ? versionNumbersA[i] : 0) >
  //         (i < versionBSize ? versionNumbersB[i] : 0)) {
  //       shouldUpdate = false;
  //     } else if ((i < versionASize ? versionNumbersA[i] : 0) <
  //         (i < versionBSize ? versionNumbersB[i] : 0)) {
  //       shouldUpdate = true;
  //     }
  //     if (i == 0 && shouldUpdate == false) break;
  //   }
  //
  //   if (shouldUpdate) {
  //     await showDialog(
  //       context: context,
  //       barrierDismissible: true,
  //       builder: (BuildContext context) {
  //         return WillPopScope(
  //             child: AlertDialog(
  //               title: const Text('Actualización Disponible!'),
  //               content: Text(
  //                   'Existe una nueva versión (${versionCheck.storeVersion!}) más reciente que su versión actual (${versionCheck.packageVersion}), desea actualizar?'),
  //               actions: [
  //                 TextButton(
  //                   child: const Text('Quizas Despues'),
  //                   onPressed: () {
  //                     Navigator.of(context, rootNavigator: true).pop();
  //                   },
  //                 ),
  //                 TextButton(
  //                   child: const Text('Actualizar'),
  //                   onPressed: () async {
  //                     await launchUrl(Uri.parse(versionCheck.storeUrl!));
  //                     Navigator.of(context, rootNavigator: true).pop();
  //                   },
  //                 ),
  //               ],
  //             ),
  //             onWillPop: () => Future.value(true));
  //       },
  //     );
  //   }
  // });

  final _checker = AppVersionChecker();

  void checkVersion() async {
    _checker.checkUpdate().then((value) async {
      var upgradAvailable = value.canUpdate;
      if(upgradAvailable) {
        await showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context)
        {
          return WillPopScope(
              child: AlertDialog(
                title: Text('Actualización Disponible!', style: Theme.of(context).textTheme.titleLarge),
                content: Text(
                    'Existe una nueva versión (${value
                        .newVersion}) más reciente que su versión actual (${value
                        .currentVersion}), desea actualizar?'),
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
                      await launchUrl(Uri.parse(value.appURL!));
                      Navigator.of(context, rootNavigator: true).pop();
                    },
                  ),
                ],
              ),
              onWillPop: () => Future.value(true));
        });
      }
    });
    //await _checker.checkVersion(context);
  }


  @override
  void initState() {
    String shortcut = 'no action set';
    createTutorial();
    Future.delayed(Duration.zero,showTutorial);
    super.initState();

    // Setup App ShortCuts
    const QuickActions quickActions = QuickActions();
    quickActions.initialize((String shortcutType) {
      setState(() {
        shortcut = shortcutType;
        if( shortcut == 'calcular_envio') {
          _controller.jumpToTab(3);
        }
        if(shortcut == 'show_disponible') {
          _controller.jumpToTab(2);
          GetIt.I<CourierService>().getRecepciones(false)
          .then((value) =>
              Navigator.of(context, rootNavigator: false)
              .push(MaterialPageRoute(
              builder: (context) =>
                  RecepcionesPage(
                      isRetenio: false,
                      titulo: "Disponibles",
                      recepciones: value
                          .where((element) =>
                      element.disponible ==
                          true)
                          .toList()))),);
        }
        if(shortcut == 'crear_postalerta') {
          _controller.jumpToTab(2);
          GetIt.I<CourierService>().getRecepciones(false)
              .then((value) =>
              Navigator.of(context, rootNavigator: false)
                  .push(MaterialPageRoute(
                  builder: (context) =>
                      RecepcionesPage(
                          isRetenio: false,
                          titulo: "Sin Factura",
                          recepciones: value
                              .where((element) =>
                          element.retenido ==
                              true)
                              .toList()))),);
        }
        if(shortcut == 'crear_prealerta') {
          _controller.jumpToTab(2);
          Future.delayed(const Duration(milliseconds: 1000)).then((value) =>
              GetIt.I<event.Event<UserPrealertaRequested>>().broadcast(UserPrealertaRequested())
          );
        }
      });
    });

    quickActions.setShortcutItems(<ShortcutItem>[
      if(appInfo.metricsPrefixKey != "CARIBEPACK")
        const ShortcutItem(
            type: 'calcular_envio',
            localizedTitle: 'Calcular Envío',
          icon: 'ic_launcher'
            ),
      const ShortcutItem(
        type: 'crear_prealerta',
        localizedTitle: 'Crear Pre-Alerta',
          icon: 'ic_launcher'
      ),
      const ShortcutItem(
        type: 'show_disponible',
        localizedTitle: 'Ver Disponibles',
          icon: 'ic_launcher'
      ),
      const ShortcutItem(
        type: 'crear_postalerta',
        localizedTitle: 'Crear Post-Alerta',
          icon: 'ic_launcher'
      ),
    ]).then((void _) {
      setState(() {
        if (shortcut == 'no action set') {
          shortcut = 'actions ready';
        }
      });
    });

    // Setup Tab Navigation
    _controller = PersistentTabController(initialIndex: GetIt.I<AppInfo>().defaultTab);

    initConnectivity();
    //_connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);

    // Push Notifications
    // Foreground State
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showFlutterNotification(message);
    });
    // Background State
    FirebaseMessaging.onMessageOpenedApp.listen((value) => {
          if (value.notification?.body != null &&
              value.notification?.title != null)
            {
              showDialog(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: Text(value.notification!.title!,
                      style: Theme.of(context).textTheme.titleLarge),
                  content: Text(value.notification!.body!),
                ),
              )
            }
        });
    // Terminated State
    FirebaseMessaging.instance.getInitialMessage().then((value) => {
          if (value?.notification?.body != null &&
              value?.notification?.title != null)
            {
              showDialog(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: Text(value!.notification!.title!,
                      style: Theme.of(context).textTheme.titleLarge),
                  content: Text(value.notification!.body!),
                ),
              )
            }
        });

    // Check for new version of app
    checkVersion();

    // Listen to SessionExpired Event
    GetIt.I<Event<SessionExpired>>().subscribe((args) {
      _controller.index = 2;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: Duration(milliseconds: 5000),
          margin: EdgeInsets.only(
              bottom: kBottomNavigationBarHeight, right: 2, left: 2),
          content:
          Text('Su contraseña ha cambiado, debe entrar nuevamente.'),
        ),
      );
    });

    //
    FlutterNativeSplash.remove();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> initConnectivity() async {
    late ConnectivityResult result;
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      debugPrint(e.toString());
    }
    if(!mounted) {
      return Future.value(null);
    }
    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
      if (result == ConnectivityResult.none) {
        connectivityWasLost = true;
        connectivityWasLostAt = DateTime.now();
        ScaffoldMessenger.of(context).showMaterialBanner(MaterialBanner(
            backgroundColor: Theme.of(context).errorColor,
            content: Text(
                "Se ha perdido la conexión a internet, algunas funciones de la aplicación no estarán disponibles.",
                style: Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(color: Colors.white)),
            actions: [
              IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                  },)
            ]
        ));
      } else {
        if (connectivityWasLost) {
          ScaffoldMessenger.of(context).clearMaterialBanners();
          //
          connectivityWasLost = false;
          if(connectivityWasLostAt != null) {
            var duration = DateTime.now().difference(connectivityWasLostAt!);
            connectivityWasLostAt = null;
            if(duration.inSeconds < 1) {
              return;
            }
          }
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.only(
                      bottom: MediaQuery.of(context).size.height - 150,
                      right: 20,
                      left: 20),
                  content: const Text("Conexión a internet restaurada!")));
        }
      }
  }

  // TabBar Setup
  bool _hideNavBar = false;
  late PersistentTabController _controller;
  final NavBarStyle _navBarStyle = NavBarStyle.style14; // 17
  final bool _hideNavigationBarWhenKeyboardShows = true;
  final bool _resizeToAvoidBottomInset = true;
  final bool _stateManagement = true;
  final bool _handleAndroidBackButtonPress = true;
  final bool _popAllScreensOnTapOfSelectedTab = true;
  final bool _confineInSafeArea = true;

  final GlobalKey keyBottomNavigation = GlobalKey();
  final GlobalKey keyNewsBottomNavigation = GlobalKey();
  final GlobalKey keyLocationsBottomNavigation = GlobalKey();
  final GlobalKey keyMainBottomNavigation = GlobalKey();
  final GlobalKey keyCalculatorBottomNavigation = GlobalKey();
  final GlobalKey keyServicesBottomNavigation = GlobalKey();
  final GlobalKey keyOtherBottomNavigation = GlobalKey();

  late TutorialCoachMark tutorialCoachMark;

  List<Widget> _buildScreens() {
    return [
      const NoticiasPage(),
      const SucursalesPage(),
      const CourierPage(),
      if(appInfo.metricsPrefixKey != "CARIBEPACK")
        const CalculadoraPage(),
      if(appInfo.metricsPrefixKey == "CARIBEPACK")
        const ServiciosPage(),
      const AdicionalInfoPage()
    ];
  }

  List<PersistentBottomNavBarItem> _navbarItems() {
    return [
      PersistentBottomNavBarItem(
          icon: Icon(
            Icons.feed_outlined,
            key: keyNewsBottomNavigation,
            color: Theme.of(context).appBarTheme.foregroundColor,size: 35,
          ),
          title: null, //'Noticias',
          activeColorPrimary: Theme.of(context).appBarTheme.foregroundColor!,
          inactiveIcon: Icon(
            Icons.feed_outlined,
            key: keyNewsBottomNavigation,
            color: Theme.of(context).appBarTheme.foregroundColor!.withOpacity(0.7),
            size: 25,
          )),
      PersistentBottomNavBarItem(
          icon: Icon(
            Icons.place_outlined,
            key: keyLocationsBottomNavigation,
            color: Theme.of(context).appBarTheme.foregroundColor,size: 35,
          ),
          activeColorPrimary: Theme.of(context).appBarTheme.foregroundColor!,
          title: null, //'Sucursales',
          inactiveIcon: Icon(Icons.place_outlined,
            key: keyLocationsBottomNavigation,
            size: 25,
            color: Theme.of(context).appBarTheme.foregroundColor!.withOpacity(0.7),
          )),
      if(appInfo.pushChannelTopic == "TAINO")
        PersistentBottomNavBarItem(
            icon: Container(
              key: keyMainBottomNavigation,
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle
              ),
              //color: Colors.white,
              child: Image.asset(appInfo.centerIconImage),
              height: appInfo.centerIconSize, width: appInfo.centerIconSize,
            ),
            inactiveIcon: Container(
              key: keyMainBottomNavigation,
              padding: const EdgeInsets.all(5),
              decoration:  BoxDecoration(
                  color: Colors.white.withOpacity(1),
                  shape: BoxShape.circle
              ),
              //color: Colors.transparent,
              child: Image.asset(appInfo.centerIconImage),
              height: appInfo.centerInactiveIconSize, width: appInfo.centerInactiveIconSize,
            ),
            title: null, //'Inicio',
            activeColorPrimary: Colors.transparent,
            inactiveColorPrimary: Colors.transparent),
      if(appInfo.pushChannelTopic != "TAINO" )
        PersistentBottomNavBarItem(
            icon: Container(
              key: keyMainBottomNavigation,
              decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle
              ),
              //color: Colors.white,
              child: Image.asset(appInfo.centerIconImage),
              // height: appInfo.centerIconSize, width: appInfo.centerIconSize,
            ),
            inactiveIcon: Container(
              key: keyMainBottomNavigation,
              padding: const EdgeInsets.all(5),
              decoration:  BoxDecoration(
                  color: appInfo.pushChannelTopic == "FIXOCARGO" || appInfo.pushChannelTopic == "PICKNSEND" || appInfo.pushChannelTopic == "JETPACK" ? Colors.transparent : Colors.white.withOpacity(1),
                  shape: BoxShape.circle
              ),
              //color: Colors.transparent,
              child: Image.asset(appInfo.centerIconImage),
              // height: appInfo.centerInactiveIconSize, width: appInfo.centerInactiveIconSize,
            ),
            title: null, //'Inicio',
            activeColorPrimary: Colors.transparent,
            inactiveColorPrimary: Colors.transparent),
      if(appInfo.metricsPrefixKey != "CARIBEPACK")
        PersistentBottomNavBarItem(
          icon: Icon(
            Icons.calculate_outlined,
            key: keyCalculatorBottomNavigation,
            color: Theme.of(context).appBarTheme.foregroundColor,size: 35,
          ),
          activeColorPrimary: Theme.of(context).appBarTheme.foregroundColor!,
          title: null, //'Calculadora',
          inactiveIcon: Icon(Icons.calculate_outlined,
            key: keyCalculatorBottomNavigation,
            size: 25,
            color: Theme.of(context).appBarTheme.foregroundColor!.withOpacity(0.7),
          )),
      if(appInfo.metricsPrefixKey == "CARIBEPACK")
        PersistentBottomNavBarItem(
            icon: Icon(
              Icons.room_service,
              key: keyServicesBottomNavigation,
              color: Theme.of(context).appBarTheme.foregroundColor,size: 35,
            ),
            activeColorPrimary: Theme.of(context).appBarTheme.foregroundColor!,
            title: null, //'Calculadora',
            inactiveIcon: Icon(Icons.room_service,
              key: keyServicesBottomNavigation,
              size: 25,
              color: Theme.of(context).appBarTheme.foregroundColor!.withOpacity(0.7),
            )),
      PersistentBottomNavBarItem(
          icon: Icon(
            Icons.info_outline,
            key: keyOtherBottomNavigation,
            color: Theme.of(context).appBarTheme.foregroundColor, size: 35,
          ),
          activeColorPrimary: Theme.of(context).appBarTheme.foregroundColor!,
          title: null, //'Más',
          inactiveIcon: Icon(Icons.info_outline,
            key: keyOtherBottomNavigation,
            size: 25,
            color: Theme.of(context).appBarTheme.foregroundColor!.withOpacity(0.7),
          )),
    ];
  }

  _MainAppShellState() {
    GetIt.I<event.Event<ToogleBarEvent>>().subscribe((args) {
      _hideNavBar = !(args?.show ?? true);
      setState(() {});
    });
  }

  Future<bool> showSnackBar() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 600),
        margin: EdgeInsets.only(
            bottom: kBottomNavigationBarHeight, right: 2, left: 2),
        content:
            Text('Presione el boton nuevamente para salir de la aplicación.'),
      ),
    );
    return false;
  }

  void hideSnackBar() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  DateTime oldTime = DateTime.now();
  DateTime newTime = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: PersistentTabView(context,
            key: keyBottomNavigation,
            controller: _controller,
            hideNavigationBar: _hideNavBar,
            navBarStyle: _navBarStyle,
            screens: _buildScreens(),
            items: _navbarItems(),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor!,
            confineInSafeArea: _confineInSafeArea,
            handleAndroidBackButtonPress: _handleAndroidBackButtonPress,
            resizeToAvoidBottomInset: _resizeToAvoidBottomInset,
            stateManagement: _stateManagement,
            hideNavigationBarWhenKeyboardShows:
                _hideNavigationBarWhenKeyboardShows,
            navBarHeight: kBottomNavigationBarHeight,
            margin: EdgeInsets.zero,
            popActionScreens: PopActionScreensType.all,
            bottomScreenMargin: 0.0,
            popAllScreensOnTapOfSelectedTab: _popAllScreensOnTapOfSelectedTab,
            decoration: NavBarDecoration(
              colorBehindNavBar: Theme.of(context).backgroundColor,
              borderRadius: const BorderRadius.all(Radius.zero),
            ),
            itemAnimationProperties: const ItemAnimationProperties(
              duration: Duration(milliseconds: 400),
              curve: Curves.ease,
            ),
            screenTransitionAnimation: const ScreenTransitionAnimation(
              animateTabTransition: true,
              curve: Curves.easeInCirc,
              duration: Duration(milliseconds: 100),
            ),
            onItemSelected: (idx)  {
              cache.write('lastSelectedTab', idx.toString());
            },
            onWillPop: (context) async {
              newTime = DateTime.now();
              int difference = newTime.difference(oldTime).inMilliseconds;
              oldTime = newTime;
              if (difference < 1000) {
                hideSnackBar();
                return true;
              } else {
                return await showSnackBar();
              }
        }
      )
    );
  }

  void showTutorial() async {
    String tutorialShown = await cache.load('tutorialShown',"");
    if(tutorialShown.isEmpty) {
      tutorialCoachMark.show(context: context);
    }
  }

  void createTutorial() {
    tutorialCoachMark = TutorialCoachMark(
      targets: _createTargets(),
      colorShadow: Colors.black,
      textSkip: "SALIR",
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: () async {
        await cache.write('tutorialShown',"X");
      },
      onClickOverlay: (target) {
        tutorialCoachMark.next();
      },
      onSkip: () async {
        await cache.write('tutorialShown',"X");
      },
    );
  }

  TargetFocus _createTarget(final String identity, final GlobalKey? key, final String tutorialText )
  {
    return TargetFocus(
      identify: identity,
      keyTarget: key,
      alignSkip: Alignment.topRight,
      enableOverlayTab: true,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          builder: (context, controller) {
            return Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tutorialText,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  List<TargetFocus> _createTargets() {
    List<TargetFocus> targets = [];
    targets.add(_createTarget("keyNewsBottomNavigation",keyNewsBottomNavigation,"Mantengase al día con nuestras ofertas y anuncios."));
    targets.add(_createTarget("keyLocationsBottomNavigation",keyLocationsBottomNavigation,"Conozca sobre nuestras oficinas, ubicación, horario de servicio y vías de contacto."));
    targets.add(_createTarget("keyMainBottomNavigation",keyMainBottomNavigation,"Acceda a su cuenta, consulte el estatus de sus paquetes y gestione sus operaciones."));
    if(appInfo.metricsPrefixKey != "CARIBEPACK") {
      targets.add(_createTarget("keyCalculatorBottomNavigation",keyCalculatorBottomNavigation,"Estime el costo de sus paquetes usando nuestra calculadora."));
    }
    if(appInfo.metricsPrefixKey == "CARIBEPACK") {
      targets.add(_createTarget("keyServicesBottomNavigation",keyServicesBottomNavigation,"Conozca nuestros servicios."));
    }
    targets.add(_createTarget("keyOtherBottomNavigation",keyOtherBottomNavigation,"Conozca más sobre nosotros y solicite de nuestra asistencia."));
    return targets;
  }

}

