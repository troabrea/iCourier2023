import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

import '../design_system/overlay_components.dart';
import '../services/courier_service.dart';
import '../services/model/login_model.dart';
import '../theme/brand_config.dart';

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
    final config = GetIt.I<BrandConfig>();
    final addresses = widget.userProfile.buzones.isEmpty
        ? [
            InfoBuzon(
              direccion: widget.userProfile.direccionBuzon,
              nombre: 'direccion_miami'.tr(),
            ),
          ].where((address) => address.direccion.isNotEmpty).toList()
        : widget.userProfile.buzones;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: Semantics(
            button: true,
            label: 'editar_perfil'.tr(),
            child: InkWell(
              onTap: _updatePhoto,
              customBorder: const CircleBorder(),
              child: CircleAvatar(
                radius: 52,
                foregroundImage: widget.userProfile.fotoPerfilUrl.isEmpty
                    ? null
                    : NetworkImage(widget.userProfile.fotoPerfilUrl),
                child: widget.userProfile.fotoPerfilUrl.isEmpty
                    ? const Icon(Icons.person_outline, size: 48)
                    : null,
              ),
            ),
          ),
        ),
        if (_updatingPhoto) const LinearProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          widget.userProfile.nombre,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          widget.userProfile.cuenta,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 20),
        Center(child: CarnetQR(accountCode: widget.userProfile.cuenta)),
        const SizedBox(height: 16),
        Text(
          widget.userProfile.nombreSucursal,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        for (final address in addresses)
          Card(
            child: ListTile(
              title: Text(address.nombre),
              subtitle: Text(address.direccion),
              trailing: IconButton(
                tooltip: 'copiar'.tr(),
                onPressed: () => Clipboard.setData(
                  ClipboardData(text: address.direccion),
                ),
                icon: const Icon(Icons.copy_outlined),
              ),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          height: 64,
          child: Image.asset(config.assets.logoWide, fit: BoxFit.contain),
        ),
      ],
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
