import 'dart:convert';

import 'package:app_popup_menu/app_popup_menu.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/courier/courier_webview.dart';
import 'package:icourier/services/model/login_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:event/event.dart' as event;
import '../apps/appinfo.dart';
import '../services/app_events.dart';
import '../services/courier_service.dart';
import 'carnet_usuario.dart';

class CourierAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CourierAppBar({Key? key, required this.hasWhatsApp}) : super(key: key);
  final bool hasWhatsApp;
  @override
  State<CourierAppBar> createState() => _CourierAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CourierAppBarState extends State<CourierAppBar> {
  String title = "mi_courier".tr();
  bool isBusy = false;
  late List<Widget> appBarActions = <Widget>[].toList();
  late UserProfile userProfile;
  bool showWhatsApp = false;
  bool showChat = false;
  String profileUrl ="";

  @override
  void initState() {
    super.initState();
    _configureWithProfile();
  }

  Future<void> _configureWithProfile() async {
    userProfile = await GetIt.I<CourierService>().getUserProfile();
    final oldProfileUrl = profileUrl;
    profileUrl = await GetIt.I<CourierService>().empresaOptionValue("ProfileUrl");
    if(profileUrl.isEmpty) {
      profileUrl = await GetIt.I<CourierService>().empresaOptionValue("EditProfileUrl");
    }

    setState(() {
      if(oldProfileUrl != profileUrl || showWhatsApp != userProfile.whatsappSucursal.isNotEmpty || (showChat != (!showWhatsApp && userProfile.chatUrl.isNotEmpty)) ) {
        showWhatsApp = userProfile.whatsappSucursal.isNotEmpty;
        showChat = !showWhatsApp && userProfile.chatUrl.isNotEmpty;
        appBarActions.clear();
        GetIt.I<Event<LoginChanged>>().broadcast(LoginChanged(userProfile.cuenta.isNotEmpty, userProfile.cuenta));
      }

    });
  }

  @override
  Widget build(BuildContext context) {
    var loginChangedEvent = GetIt.I<Event<LoginChanged>>();
    loginChangedEvent.subscribe((args) {
      setState(() {
        title = args!.loggedIn ? args.account : "inicio_session".tr();

        if (args.loggedIn) {
          if (appBarActions.isEmpty) {
            appBarActions = [
              IconButton(
                icon: Icon(Icons.refresh,
                  color: Theme.of(context).appBarTheme.foregroundColor,
                ),
                onPressed: () {
                  GetIt.I<Event<CourierRefreshRequested>>()
                      .broadcast(CourierRefreshRequested());
                },
              ),
              IconButton(
                icon: Icon(Icons.badge_outlined,
                  color: Theme.of(context).appBarTheme.foregroundColor,
                ),
                onPressed: () => {showMembershipBadge(context)},
              ),
              if(showWhatsApp)
              IconButton(
                icon: FaIcon(FontAwesomeIcons.whatsapp,
                  color: Theme.of(context).appBarTheme.foregroundColor,
                ),
                onPressed: ()  {
                    chatWithSucursal();
                  },
              ),
              if(showChat)
                IconButton(
                  icon: Icon(Icons.chat,
                    color: Theme.of(context).appBarTheme.foregroundColor,
                  ),
                  onPressed: () async {
                    launchUrl(Uri.parse(userProfile.chatUrl));
                  },
                ),
              if(profileUrl.isEmpty)
                IconButton(
                  icon: Icon(
                    Icons.person,
                    color: Theme.of(context).appBarTheme.foregroundColor,
                  ),
                  onPressed: () => {doLogout()},
                ),
              if(profileUrl.isNotEmpty)
                AppPopupMenu<int>(
                  menuItems: [
                    PopupMenuItem(value: 1,child:  Text('editar_perfil'.tr()),),
                    PopupMenuItem(value: 2,child:  Text('cerrar_session'.tr()),),
                  ],
                  icon: Icon(Icons.person, color: Theme.of(context).appBarTheme.foregroundColor,),
                  onSelected: (x) =>
                  {
                    if(x==1) doEditProfile(context) else doLogout()
                  },
                ),

            ].toList();
          }
        } else {
          appBarActions = <Widget>[].toList();
        }
      });
    });

    return AppBar(
      title: Text(title),
      actions: appBarActions,
      automaticallyImplyLeading: true,
    );
  }

  Future<void> chatWithSucursal() async {
    var whatsApp = userProfile.whatsappSucursal; // (await GetIt.I<CourierService>().getEmpresa()).telefonoVentas;
    if (whatsApp.isNotEmpty) {
      var _url = Uri.parse("whatsapp://send?phone=$whatsApp");
      if (!await launchUrl(_url)) {
        throw 'Could not launch $_url';
      }
    }
  }

  Future doLogout() async {
    var allAcounts = await  GetIt.I<CourierService>().getStoredAccounts();

    List<Widget> getActions(BuildContext context)
    {
      List<Widget> actions = List.empty(growable: true);
      if(allAcounts.length > 1) {
        allAcounts = allAcounts.where((element) => element.userAccount != title).toList();
        for (var element in allAcounts) {
          actions.add(  OutlinedButton(
            onPressed: () {Navigator.pop(context, element.userAccount);},
            child: Text('cambiar_cuenta'.tr(args: [element.userAccount]),),
            // style: OutlinedButton.styleFrom(backgroundColor: Theme.of(context).textTheme.bodyMedium!.color, textStyle: Theme.of(context).textTheme.bodyLarge),
          ) );
        }
        actions.add( const Divider() );
      }

      actions.add( Row( mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FilledButton(
            onPressed: () => {Navigator.pop(context, "cerrar")},
            child: Text('si'.tr()),
          ),
          // IconButton(
          //   onPressed: () => {Navigator.pop(context, "")},
          //   icon: const Icon(Icons.close),
          // ),
          FilledButton(
            onPressed: () => {Navigator.pop(context, "")},
            child: Text('no'.tr()),
          ),
        ],
      ));

      return actions;
    }
    if (!context.mounted) return;

    var dlgResult = await showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          actionsAlignment: MainAxisAlignment.spaceBetween,
              title: Text('confirme'.tr(),
                  style: Theme.of(context).textTheme.titleLarge),
              content: Text('confirme_cerrar_session'.tr()),
              actions: getActions(context),));
    if (dlgResult != null) {
      if (dlgResult == "cerrar") {
        GetIt.I<Event<LogoutRequested>>().broadcast(LogoutRequested());
      } else {
        var ok = await GetIt.I<CourierService>().switchUserAccount(dlgResult);
        if(ok) {
          GetIt.I<Event<LoginChanged>>().broadcast(LoginChanged(true, dlgResult));
          GetIt.I<Event<CourierRefreshRequested>>().broadcast(CourierRefreshRequested());
        }
      }
    }
  }

  Future<void> showMembershipBadge(BuildContext context) async {
    var userProfile = await GetIt.I<CourierService>().getUserProfile();
    //NavbarNotifier.hideBottomNavBar = true;
    GetIt.I<event.Event<ToogleBarEvent>>().broadcast(ToogleBarEvent(false));
    if (!context.mounted) return;
    await showModalBottomSheet(
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        context: context,
        builder: (builder) {
          return CarnetUsuario(userProfile: userProfile);
        });
    GetIt.I<event.Event<ToogleBarEvent>>().broadcast(ToogleBarEvent(true));
  }

  doEditProfile(BuildContext context) async {
    if (!context.mounted) return;

    final appInfo = GetIt.I<AppInfo>();
    final map = await GetIt.I<CourierService>().getProfileUrl();
    final userId = map['UsuarioID'] ?? "";
    final userPwd = map['UsuarioPW'] ?? "";

    final String encodedCompany =
    base64Encode(const Utf8Encoder().convert(appInfo.companyId));

    final String encodedUser =
    base64Encode(const Utf8Encoder().convert(userId));

    final String encodedPwd =
    base64Encode(const Utf8Encoder().convert(userPwd));


    final functionUrl= 'https://icourier.barolit.net/EditProfile/$encodedCompany/$encodedUser/$encodedPwd';
    await launchUrl(Uri.parse( functionUrl ), mode: LaunchMode.externalApplication);


  }
}
