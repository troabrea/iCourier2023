import 'dart:convert';
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/adicional/appbrowser.dart';
import 'package:icourier/helpers/dialogs.dart';
import 'package:icourier/services/app_events.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../apps/appinfo.dart';
import 'package:image_picker/image_picker.dart';


import '../services/courier_service.dart';
import '../services/model/login_model.dart';

class CuentasUsuario extends StatefulWidget {
  final UserProfile userProfile;
  final appInfo = GetIt.I<AppInfo>();

  CuentasUsuario({super.key, required this.userProfile});

  @override
  State<CuentasUsuario> createState() => _CuentasUsuarioState();
}

class _CuentasUsuarioState extends State<CuentasUsuario> {
  late UserProfile userProfile;
  final ImagePicker _picker = ImagePicker();
  bool isBusy = false;
  String profileUrl = "";
  final accountList = <UserAccount>[].toList();

  //NavbarNotifier.hideBottomNavBar = true;
  _CuentasUsuarioState();

  @override
  void initState() {
    loadData();
    super.initState();
  }

  Future<void> loadData() async {
    var list = await GetIt.I<CourierService>().getStoredAccounts();
    userProfile = await GetIt.I<CourierService>().getUserProfile();
    profileUrl = await GetIt.I<CourierService>().empresaOptionValue("ProfileUrl");
    if(profileUrl.isEmpty) {
      profileUrl = await GetIt.I<CourierService>().empresaOptionValue("EditProfileUrl");
    }
    accountList.clear();
    accountList.addAll(list);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
          decoration: ShapeDecoration(
              color: Theme.of(context).appBarTheme.backgroundColor,
              shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)))),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                    child: AutoSizeText("sus_cuentas".tr(),
                        maxLines: 1,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context)
                                .appBarTheme
                                .foregroundColor))),
              ),
            ],
          )),
      SizedBox(
        height: accountList.isNotEmpty ? min(accountList.length * 100, 500) : 200,
        child: ListView.separated(
          separatorBuilder: (ctx,idx) => const Divider(),
          itemBuilder: (ctx, idx) => ListTile(
            onTap: () { switchToAccount(accountList[idx]); },
            title: Text(accountList[idx].userAccount),
            subtitle: Text(accountList[idx].nombre),
            leading: userProfile.cuenta == accountList[idx].userAccount ? const Icon(Icons.check_circle) : const Icon(Icons.circle_outlined),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if(profileUrl.isNotEmpty && userProfile.cuenta == accountList[idx].userAccount)
                  IconButton.filledTonal(onPressed: () {doEditProfile(context);}, icon: const Icon(Icons.edit), color: Theme.of(context).colorScheme.primary),
                IconButton.filledTonal(onPressed: () {doForgetAccount( accountList[idx] );}, icon: const Icon(Icons.delete), color: Theme.of(context).colorScheme.error,),
              ],
            ),
          ),
          itemCount: accountList.length,
        ),
      ),
      SafeArea(child: OutlinedButton(onPressed: () {doLogout(context);}, child: Text("${"agregar_cuenta".tr()} / ${"cerrar_session".tr()}", style: TextStyle(color: Theme.of(context).colorScheme.primary))))
    ]);
  }
  Future<void> doForgetAccount(UserAccount userAccount) async {
    if(!await confirmDialog(context, "confirme_borrar_cuenta".tr(), "si".tr(), "no".tr())) {
      return;
    }
    final newList = await GetIt.I<CourierService>().removeAccountFromStore(userAccount);
    setState(() {
      accountList.clear();
      accountList.addAll(newList);
    });
    if(newList.isEmpty) {
      if(!context.mounted) return;
      doLogout(context);
    }
  }
  void doLogout(BuildContext context) {
    Navigator.of(context).pop();
    GetIt.I<Event<LogoutRequested>>().broadcast(LogoutRequested());
  }
  Future<void> switchToAccount(UserAccount userAccount) async {
    Navigator.of(context).pop();
    var ok = await GetIt.I<CourierService>().switchUserAccount(userAccount.userAccount);
    if(ok) {
      GetIt.I<Event<LoginChanged>>().broadcast(LoginChanged(true, userAccount.userAccount, userAccount.nombre));
      GetIt.I<Event<CourierRefreshRequested>>().broadcast(CourierRefreshRequested());
    }
  }

  doEditProfile(BuildContext context) async {

    Navigator.of(context).pop();

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

    if (!context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (BuildContext context) =>  AppBrowser(initialUrl: functionUrl, title: "Edición de Perfil"),
    ),);

    // await launchUrl(Uri.parse( functionUrl ), mode: LaunchMode.externalApplication);


  }
}


