import 'dart:convert';

import 'package:app_popup_menu/app_popup_menu.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/courier/courier_webview.dart';
import 'package:icourier/courier/cuentas_usuario.dart';
import 'package:icourier/courier/mensajes_usuario.dart';
import 'package:icourier/services/model/login_model.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:event/event.dart' as event;
import '../apps/appinfo.dart';
import '../services/app_events.dart';
import '../services/courier_service.dart';
import 'carnet_usuario.dart';

class CourierAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CourierAppBar({super.key, required this.hasWhatsApp, required this.showProfile });
  final bool hasWhatsApp;
  final bool showProfile;
  @override
  State<CourierAppBar> createState() => _CourierAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CourierAppBarState extends State<CourierAppBar> {
  String title = "mi_courier".tr();
  String subtitle = "";
  String fotoPerfil = "";
  bool isBusy = false;
  int unreadMessages = 0;
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
    subtitle = userProfile.nombre;
    fotoPerfil = userProfile.fotoPerfilUrl;
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
        GetIt.I<Event<LoginChanged>>().broadcast(LoginChanged(userProfile.cuenta.isNotEmpty, userProfile.cuenta, userProfile.nombre));
      }

    });
  }

  @override
  Widget build(BuildContext context) {
    var loginChangedEvent = GetIt.I<Event<LoginChanged>>();
    var unreadMessagesChanged = GetIt.I<Event<UnreadMessagesChanged>>();

    unreadMessagesChanged.subscribe((args) {
      setState(() {
        unreadMessages = args?.unreadCount ?? 0;
      });

    });

    void updateProfilePhoto() async {
      userProfile = await GetIt.I<CourierService>().getUserProfile();
      setState( () {
        fotoPerfil = userProfile.fotoPerfilUrl;
      });
    }

    loginChangedEvent.subscribe((args) {
      setState(() {
        title = args!.loggedIn ? args.account : "inicio_session".tr();
        subtitle = args.loggedIn ? args.name : "";
        fotoPerfil = "";
        if (args.loggedIn) {
          // Foto
          updateProfilePhoto();
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
              // if(profileUrl.isEmpty)
              //   IconButton(
              //     icon: Icon(
              //       Icons.person,
              //       color: Theme.of(context).appBarTheme.foregroundColor,
              //     ),
              //     onPressed: () => {doLogout()},
              //   ),
              // if(profileUrl.isNotEmpty)
              //   AppPopupMenu<int>(
              //     menuItems: [
              //       PopupMenuItem(value: 1,child:  Text('editar_perfil'.tr()),),
              //       PopupMenuItem(value: 2,child:  Text('cerrar_session'.tr()),),
              //     ],
              //     icon: Icon(Icons.person, color: Theme.of(context).appBarTheme.foregroundColor,),
              //     onSelected: (x) =>
              //     {
              //       if(x==1) doEditProfile(context) else doLogout()
              //     },
              //   ),

            ].toList();
          }
        } else {
          appBarActions = <Widget>[].toList();
        }
      });
    });

    return AppBar(
      title: widget.showProfile ?  OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide.none, // (color: Theme.of(context).appBarTheme.foregroundColor!, width: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8.0)
        ),
        onPressed: () => {showProfileOptions(context)},
        child: FittedBox(
          child: Row(
            children: [
              CachedNetworkImage(imageUrl: fotoPerfil,
                width: 30,
                height: 30,
                imageBuilder: (context, imageProvider) => Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.fill,
                      ),
                    )),
                placeholder: (context, url) => const Icon(Icons.person),
                errorWidget: (context, url, error) => const Icon(Icons.person),
              ),
              const SizedBox(width: 2,),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onPrimary),),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onPrimary),)
                ],
              ),
            ],
          ),
        ),
      ) : Text(title),
      actions: [
        ...appBarActions,
        if(unreadMessages > 0)
          Badge(alignment: Alignment.topLeft, label: Text(unreadMessages.toString()), child: IconButton(onPressed: () {showMessages(context);}, icon: const Icon(Icons.notifications_none))),
        if(unreadMessages <= 0)
        IconButton(onPressed: () {showMessages(context);}, icon: const Icon(Icons.notifications_none)),
      ],
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

  Future<void> showMessages(BuildContext context) async {
    var messages = await GetIt.I<CourierService>().getMensajes();
    var userProfile = await GetIt.I<CourierService>().getUserProfile();
    GetIt.I<event.Event<ToogleBarEvent>>().broadcast(ToogleBarEvent(false));
    if (!context.mounted) return;
    await showModalBottomSheet(
        isScrollControlled: true,
        useSafeArea: true,
        useRootNavigator: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        context: context,
        builder: (builder) {
          return MensajesUsuario();
        });
    GetIt.I<event.Event<ToogleBarEvent>>().broadcast(ToogleBarEvent(true));
  }

  Future<void> showProfileOptions(BuildContext context) async {
    var userProfile = await GetIt.I<CourierService>().getUserProfile();
    GetIt.I<event.Event<ToogleBarEvent>>().broadcast(ToogleBarEvent(false));
    if (!context.mounted) return;
    await showModalBottomSheet(
        isScrollControlled: true,
        useSafeArea: true,
        useRootNavigator: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        context: context,
        builder: (builder) {
          return CuentasUsuario(userProfile: userProfile);
        });
    GetIt.I<event.Event<ToogleBarEvent>>().broadcast(ToogleBarEvent(true));
  }

  Future<void> showMembershipBadge(BuildContext context) async {
    var userProfile = await GetIt.I<CourierService>().getUserProfile();
    //NavbarNotifier.hideBottomNavBar = true;
    GetIt.I<event.Event<ToogleBarEvent>>().broadcast(ToogleBarEvent(false));
    if (!context.mounted) return;
    await showModalBottomSheet(
      useRootNavigator: true,
        useSafeArea: true,
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
