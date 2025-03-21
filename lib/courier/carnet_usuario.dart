import 'package:auto_size_text/auto_size_text.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import '../apps/appinfo.dart';
import 'package:image_picker/image_picker.dart';
import 'package:user_profile_avatar/user_profile_avatar.dart';

import '../services/courier_service.dart';
import '../services/model/login_model.dart';

class CarnetUsuario extends StatefulWidget {
  final UserProfile userProfile;
  final appInfo = GetIt.I<AppInfo>();
  CarnetUsuario({Key? key, required this.userProfile}) : super(key: key);

  @override
  State<CarnetUsuario> createState() => _CarnetUsuarioState();
}

class _CarnetUsuarioState extends State<CarnetUsuario> {
  //late UserProfile userProfile;
  final ImagePicker _picker = ImagePicker();
  bool isBusy = false;
  //NavbarNotifier.hideBottomNavBar = true;
  _CarnetUsuarioState();
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
                    child: Text("carnet_membresia".tr(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context)
                                .appBarTheme
                                .foregroundColor))),
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 30,
        ),
        Center(
          child: UserProfileAvatar(
            avatarUrl: widget.userProfile.fotoPerfilUrl,
            onAvatarTap: () async {
              var xFile = await _picker.pickImage(source: ImageSource.gallery);
              if (xFile != null) {
                //
                setState(() {
                  isBusy = true;
                });
                //
                await GetIt.I<CourierService>().updateProfilePhoto(xFile);
                widget.userProfile.fotoPerfilUrl =
                    (await GetIt.I<CourierService>().getUserProfile())
                        .fotoPerfilUrl;
                isBusy = false;
                //
                setState(() {});
              }
            },
            avatarSplashColor: Theme.of(context).primaryColor,
            radius: 50,
            isActivityIndicatorSmall: false,
            avatarBorderData: AvatarBorderData(
              borderColor: Theme.of(context).primaryColorDark,
              borderWidth: 5.0,
            ),
          ),
          // ClipOval( child: Image.network(userProfile.fotoPerfilUrl,
          //
          //   fit: BoxFit.cover, width: 160, height: 160,)
          // ),
        ),
        if (isBusy) const LinearProgressIndicator(),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
              child: AutoSizeText(widget.userProfile.nombre,
                  maxLines: 1, style: Theme.of(context).textTheme.titleLarge)),
        ),
        Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, right: 8.0),
            child: Center(
                child: Text(widget.userProfile.cuenta,
                    style: Theme.of(context).textTheme.titleMedium))),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: BarcodeWidget(
              height: 100,
              width: 100,
              barcode: Barcode.qrCode(),
              color: Theme.of(context).textTheme.titleMedium!.color!,
              data: widget.userProfile.cuenta,
              errorBuilder: (context, error) => Center(child: Text(error)),
            ),
          ),
        ),
        Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
                child: Text(widget.userProfile.nombreSucursal,
                    style: Theme.of(context).textTheme.headlineMedium))),
        if (widget.userProfile.direccionBuzon.isNotEmpty || widget.userProfile.buzones.isNotEmpty)
          buildDireccionBuzon(context, widget.userProfile),
        Image.asset(
          widget.appInfo.metricsPrefixKey == "TUPAQ"
              ? "images/tupaq/icon_transparent.png"
              : widget.appInfo.brandLogoImage,
          width: 75,
          height: 75,
        ),
        const SizedBox(
          height: 20,
        )
      ],
    );
  }
}

Widget buildDireccionBuzon(BuildContext context, UserProfile userProfile) {
  return Column(
    children: [
      if (userProfile.buzones.isEmpty)
        Text('direccion_miami'.tr(),
            style: Theme.of(context).textTheme.bodySmall),
      if (userProfile.buzones.isEmpty)
        const SizedBox(
          height: 10,
        ),
      if (userProfile.buzones.isEmpty)
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(
              userProfile.direccionBuzon,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            FilledButton.icon(
              icon: const Icon(Icons.copy),
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(8)),
              onPressed: () {
                Clipboard.setData(
                    ClipboardData(text: userProfile.direccionBuzon));
              },
              label: Text('copiar'.tr()),
            )
          ],
        ),
      if (userProfile.buzones.isNotEmpty)
        SizedBox(
          height: 90,
          child: PageView.builder(
            itemCount: userProfile.buzones.length,
            itemBuilder: (context, idx) {
              return Column(
                children: [
                  Text(
                    userProfile.buzones[idx].nombre,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            userProfile.buzones[idx].direccion,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilledButton.icon(
                          icon: const Icon(Icons.copy),
                          style: FilledButton.styleFrom(
                              padding: const EdgeInsets.all(8)),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(
                                text: userProfile.buzones[idx].direccion));
                          },
                          label: Text('copiar'.tr()),
                        ),
                      )
                    ],
                  ),
                  if (userProfile.buzones.length > 1)
                    DotsIndicator(
                      dotsCount: userProfile.buzones.length,
                      position: idx,
                      decorator: DotsDecorator(
                        color: Theme.of(context).dividerColor,
                        activeColor: Theme.of(context).colorScheme.secondary,
                        size: const Size(6, 6),
                        activeSize: const Size(8, 8),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
    ],
  );
}
