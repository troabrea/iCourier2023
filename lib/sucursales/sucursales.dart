import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design_system/brand_foundations.dart';
import '../design_system/brand_states.dart';
import '../design_system/content_components.dart';
import '../design_system/core_components.dart';
import '../design_system/overlay_components.dart';
import '../services/courier_service.dart';
import '../services/model/login_model.dart';
import '../services/model/sucursal.dart';
import '../theme/brand_tokens.dart';
import 'bloc/sucursales_bloc.dart';

class SucursalesPage extends StatefulWidget {
  const SucursalesPage({super.key});

  @override
  State<SucursalesPage> createState() => _SucursalesPageState();
}

class _SucursalesPageState extends State<SucursalesPage> {
  late final SucursalesBloc _bloc;
  final _searchController = TextEditingController();
  String _query = '';
  UserProfile? _profile;
  ({double latitude, double longitude})? _here;

  @override
  void initState() {
    super.initState();
    _bloc = SucursalesBloc(GetIt.I<CourierService>())
      ..add(const LoadApiEvent());
    _loadProfile();
    _locate();
  }

  Future<void> _loadProfile() async {
    final profile = await GetIt.I<CourierService>().getUserProfile();
    if (mounted) {
      setState(() => _profile = profile);
    }
  }

  /// Resolves the customer position so each branch can show its distance.
  ///
  /// Location is optional: when the permission is refused the list simply
  /// renders without distances.
  Future<void> _locate() async {
    try {
      if (await Permission.locationWhenInUse.isDenied) {
        await Permission.locationWhenInUse.request();
      }
      if (!await Permission.locationWhenInUse.isGranted) {
        return;
      }
      final data = await Location().getLocation();
      final latitude = data.latitude;
      final longitude = data.longitude;
      if (!mounted || latitude == null || longitude == null) {
        return;
      }
      setState(() => _here = (latitude: latitude, longitude: longitude));
    } on Exception {
      // Location is a convenience here; failing to obtain it is not an error.
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: ScreenHeader.tab(title: 'sucursales'.tr()),
      body: BlocProvider.value(
        value: _bloc,
        child: BlocBuilder<SucursalesBloc, SucursalesState>(
          builder: (context, state) {
            if (state is SucursalesLoadingState) {
              return const BrandSkeleton();
            }
            if (state is SucursalesErrorState) {
              return BrandErrorState(
                onRetry: () => _bloc.add(const LoadApiEvent(ignoreCache: true)),
              );
            }
            if (state is! SucursalesLoadedState) {
              return const BrandEmptyState(
                messageKey: 'no_resultados',
                glyph: BrandIcons.branches,
              );
            }
            final query = _query.toLowerCase();
            final branches = state.sucursales
                .where(
                  (branch) =>
                      query.isEmpty ||
                      branch.nombre.toLowerCase().contains(query) ||
                      branch.ciudad.toLowerCase().contains(query) ||
                      branch.direccion.toLowerCase().contains(query),
                )
                .toList(growable: false);

            return Column(
              children: [
                BranchMap(
                  branches: branches,
                  onSelect: (branch) => _openBranch(branch),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async =>
                        _bloc.add(const LoadApiEvent(ignoreCache: true)),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        BrandSpace.lg,
                        14,
                        BrandSpace.lg,
                        BrandTabBar.height,
                      ),
                      children: [
                        _SearchField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _query = value),
                          onClear: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                        const SizedBox(height: BrandSpace.sm),
                        if (branches.isEmpty)
                          const BrandEmptyState(messageKey: 'no_resultados')
                        else
                          for (final branch in branches)
                            BranchCard(
                              branch: branch,
                              distance: _distanceTo(branch),
                              onTap: () => _openBranch(branch),
                            ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String? _distanceTo(Sucursal branch) {
    final here = _here;
    if (here == null || (branch.latitud == 0 && branch.longitud == 0)) {
      return null;
    }
    final km = _haversineKm(
      here.latitude,
      here.longitude,
      branch.latitud,
      branch.longitud,
    );
    return '${km.toStringAsFixed(1)} km';
  }

  Future<void> _openBranch(Sucursal branch) async {
    final whatsapp = _profile?.whatsappSucursal ?? '';
    await showBrandSheet<void>(
      context,
      scrollable: true,
      child: BranchSheet(
        branch: branch,
        whatsapp: whatsapp,
        onCall: branch.telefonoOficina.isEmpty
            ? null
            : () => _launchPhone(branch.telefonoOficina),
        onWhatsApp: whatsapp.isEmpty ? null : () => _launchWhatsApp(whatsapp),
        onEmail: branch.email.isEmpty ? null : () => _launchEmail(branch.email),
        onDirections: () => _launchDirections(branch),
      ),
    );
  }

  Future<void> _launchPhone(String phone) =>
      launchUrl(Uri(scheme: 'tel', path: phone));

  Future<void> _launchEmail(String email) =>
      launchUrl(Uri(scheme: 'mailto', path: email));

  Future<void> _launchWhatsApp(String phone) {
    final normalized = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return launchUrl(
      Uri.https('wa.me', '/$normalized'),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _launchDirections(Sucursal branch) => launchUrl(
        Uri.https(
          'www.google.com',
          '/maps/search/',
          {'api': '1', 'query': '${branch.latitud},${branch.longitud}'},
        ),
        mode: LaunchMode.externalApplication,
      );
}

/// Great-circle distance in kilometres.
double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const toRadians = pi / 180;
  final a = 0.5 -
      cos((lat2 - lat1) * toRadians) / 2 +
      cos(lat1 * toRadians) *
          cos(lat2 * toRadians) *
          (1 - cos((lon2 - lon1) * toRadians)) /
          2;
  return 12742 * asin(sqrt(a));
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return BrandCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          BrandGlyph(BrandIcons.branches, color: tokens.textMuted, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: tokens.body(14, weight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'buscar'.tr(),
                hintStyle: tokens.body(14, color: tokens.textMuted),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              onPressed: onClear,
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.close, size: 16, color: tokens.textMuted),
            ),
        ],
      ),
    );
  }
}
