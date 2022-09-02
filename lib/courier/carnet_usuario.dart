import 'package:auto_size_text/auto_size_text.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:user_profile_avatar/user_profile_avatar.dart';

import '../services/courierService.dart';
import '../services/model/login_model.dart';

class CarnetUsuario extends StatefulWidget {
  final UserProfile userProfile;
  const CarnetUsuario({Key? key, required this.userProfile}) : super(key: key);

  @override
  State<CarnetUsuario> createState() => _CarnetUsuarioState(userProfile);
}

class _CarnetUsuarioState extends State<CarnetUsuario> {
  UserProfile userProfile;
  final ImagePicker _picker = ImagePicker();
  bool isBusy = false;
  //NavbarNotifier.hideBottomNavBar = true;
  _CarnetUsuarioState(this.userProfile);
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
                    child: Text("Carnet de Membresía",
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
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
            avatarUrl: userProfile.fotoPerfilUrl,
            onAvatarTap: () async {
              var xFile = await _picker.pickImage(source: ImageSource.gallery);
              if(xFile != null) {
                //
                setState(() {
                  isBusy = true;
                });
                //
                await GetIt.I<CourierService>().updateProfilePhoto(xFile);
                userProfile = await GetIt.I<CourierService>().getUserProfile();
                isBusy = false;
                //
                setState(() {

                });
              }

            },
            avatarSplashColor: Theme.of(context).primaryColor,
            radius: 100,
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
        if(isBusy)
          const LinearProgressIndicator(),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
              child: AutoSizeText(userProfile.nombre, maxLines: 1,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
              )),
        ),
        Padding(
            padding: const EdgeInsets.only(
                left: 8.0, bottom: 8.0, right: 8.0),
            child: Center(
                child: Text(userProfile.cuenta,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                ))),
        Padding(padding: const EdgeInsets.only(top: 15.0, left: 8.0, bottom: 15.0, right: 8.0),
          child: Center(
            child: BarcodeWidget(
              barcode: Barcode.qrCode(),
              color: Theme.of(context).textTheme.titleMedium!.color!,
              data: userProfile.cuenta,
              errorBuilder: (context, error) => Center(child: Text(error)),
            ),
          ),),
        const SizedBox(height: 20,)
      ],
    );
  }
}