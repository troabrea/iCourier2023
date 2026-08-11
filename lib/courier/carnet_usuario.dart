import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

import '../design_system/brand_foundations.dart';
import '../design_system/core_components.dart';
import '../design_system/overlay_components.dart';
import '../services/courier_service.dart';
import '../services/model/login_model.dart';
import '../theme/brand_config.dart';
import '../theme/brand_tokens.dart';

class CarnetUsuario extends StatefulWidget {
  const CarnetUsuario({super.key, required this.userProfile});

  final UserProfile userProfile;

  @override
  State<CarnetUsuario> createState() => _CarnetUsuarioState();
}

class _CarnetUsuarioState extends State<CarnetUsuario> {
  final _picker = ImagePicker();
  bool _updatingPhoto = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final config = GetIt.I<BrandConfig>();
    final profile = widget.userProfile;
    final addresses = profile.buzones.isEmpty
        ? [
            InfoBuzon(
              direccion: profile.direccionBuzon,
              nombre: 'direccion_miami'.tr(),
            ),
          ].where((address) => address.direccion.isNotEmpty).toList()
        : profile.buzones;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        BrandSpace.lg,
        BrandSpace.xl,
        BrandSpace.lg,
        BrandTabBar.height,
      ),
      children: [
        Center(
          child: Semantics(
            button: true,
            label: 'editar_perfil'.tr(),
            child: InkWell(
              onTap: _updatePhoto,
              customBorder: const CircleBorder(),
              child: Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tokens.surfaceAlt,
                  shape: BoxShape.circle,
                  border: Border.all(color: tokens.primary, width: 3),
                  image: profile.fotoPerfilUrl.isEmpty
                      ? null
                      : DecorationImage(
                          image: NetworkImage(profile.fotoPerfilUrl),
                          fit: BoxFit.cover,
                        ),
                ),
                child: profile.fotoPerfilUrl.isEmpty
                    ? Text(
                        profile.nombre.isEmpty
                            ? config.name.characters.first.toUpperCase()
                            : profile.nombre.characters.first.toUpperCase(),
                        style: tokens.head(32, color: tokens.primary),
                      )
                    : null,
              ),
            ),
          ),
        ),
        if (_updatingPhoto)
          Padding(
            padding: const EdgeInsets.only(top: BrandSpace.sm),
            child: LinearProgressIndicator(
              color: tokens.primary,
              backgroundColor: tokens.surfaceAlt,
            ),
          ),
        const SizedBox(height: 14),
        Text(profile.nombre, textAlign: TextAlign.center, style: tokens.head(19)),
        const SizedBox(height: 2),
        Text(
          profile.cuenta,
          textAlign: TextAlign.center,
          style: tokens.body(13, color: tokens.textMuted),
        ),
        const SizedBox(height: BrandSpace.lg),
        Center(child: CarnetQR(accountCode: profile.cuenta)),
        const SizedBox(height: BrandSpace.lg),
        if (profile.nombreSucursal.isNotEmpty)
          Text(
            profile.nombreSucursal,
            textAlign: TextAlign.center,
            style: tokens.body(14, weight: FontWeight.w700),
          ),
        for (final address in addresses) ...[
          const SizedBox(height: 6),
          Text(
            address.direccion,
            textAlign: TextAlign.center,
            style: tokens.body(12, color: tokens.textMuted, height: 1.45),
          ),
          const SizedBox(height: 14),
          Center(
            child: BrandOutlineButton(
              label: 'copiar_direccion'.tr(),
              expand: false,
              pill: true,
              fontSize: 12,
              verticalPadding: 9,
              icon: Icon(Icons.copy_outlined, size: 14, color: tokens.text),
              onPressed: () => _copy(address.direccion),
            ),
          ),
        ],
        const SizedBox(height: BrandSpace.xl),
        if (config.assets.logoWide.isNotEmpty)
          SizedBox(
            height: 48,
            child: Image.asset(config.assets.logoWide, fit: BoxFit.contain),
          ),
      ],
    );
  }

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('copiar'.tr())),
    );
  }

  Future<void> _updatePhoto() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) {
      return;
    }
    setState(() => _updatingPhoto = true);
    await GetIt.I<CourierService>().updateProfilePhoto(file);
    final profile = await GetIt.I<CourierService>().getUserProfile();
    if (!mounted) {
      return;
    }
    setState(() {
      widget.userProfile.fotoPerfilUrl = profile.fotoPerfilUrl;
      _updatingPhoto = false;
    });
  }
}
