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
import '../design_system/motion_components.dart';
import '../design_system/overlay_components.dart';
import '../helpers/contact_action.dart';
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

class _SucursalesPageState extends State<SucursalesPage>
    with WidgetsBindingObserver {
  late final SucursalesBloc _bloc;
  String _query = '';
  UserProfile? _profile;
  ({double latitude, double longitude})? _here;
  Sucursal? _focused;

  /// Whether the customer has turned the permission down, which is what earns
  /// them the invitation to reconsider rather than a silently distance-less
  /// list.
  bool _locationRefused = false;

  /// A refusal the system will no longer ask about, so the only way back in is
  /// the app's own settings page.
  bool _locationBlocked = false;

  /// How long a position request is given before the screen carries on without
  /// one. Long enough for a cold GPS fix, short enough that nobody waits on it.
  static const Duration _fixTimeout = Duration(seconds: 8);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bloc = SucursalesBloc(GetIt.I<CourierService>())
      ..add(const LoadApiEvent());
    _loadProfile();
    _locate();
  }

  /// Picks the permission back up on the way in from the settings app.
  ///
  /// Without this the invitation is a trap: the customer grants the permission
  /// outside the app, comes back to the same distance-less list, and the only
  /// button on screen sends them straight back to settings.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _here == null) {
      _locate(prompt: false);
    }
  }

  Future<void> _loadProfile() async {
    final profile = await GetIt.I<CourierService>().getUserProfile();
    if (mounted) {
      setState(() => _profile = profile);
    }
  }

  /// Resolves the customer position so the list can lead with the nearest
  /// branch.
  ///
  /// Location stays optional: a refusal costs the ordering and the distances,
  /// never the screen.
  ///
  /// [prompt] gates the system dialog. The screen asks once on arrival and
  /// again only when the customer taps the invitation; the check that runs on
  /// every resume must never re-open a dialog they already dismissed.
  Future<void> _locate({bool prompt = true}) async {
    try {
      var status = await Permission.locationWhenInUse.status;
      if (status.isDenied && prompt) {
        status = await Permission.locationWhenInUse.request();
      }
      if (!status.isGranted) {
        if (mounted) {
          setState(() {
            _locationRefused = true;
            _locationBlocked = status.isPermanentlyDenied;
          });
        }
        return;
      }
      final location = Location();
      // Granting the permission is not the same as the device being able to
      // answer. With location services off system-wide, or no fix available,
      // `getLocation` simply never completes — it does not throw and does not
      // return. Left unbounded it strands the screen forever: no distances, no
      // ordering, and no invitation either, because the refusal branch above
      // was never the one taken. So it is time-boxed, and the resume check
      // tries again later.
      if (!await location.serviceEnabled()) {
        if (!prompt || !await location.requestService()) {
          return;
        }
      }
      final data = await location.getLocation().timeout(_fixTimeout);
      final latitude = data.latitude;
      final longitude = data.longitude;
      if (!mounted || latitude == null || longitude == null) {
        return;
      }
      setState(() {
        _here = (latitude: latitude, longitude: longitude);
        _locationRefused = false;
        _locationBlocked = false;
      });
    } on Exception {
      // Location is a convenience here; failing to obtain it is not an error.
      // The list keeps the backend's order and drops the distances, which is
      // the screen it shipped with.
    }
  }

  /// Recovery from the invitation: ask again, or hand over to the settings page
  /// once the system has stopped asking on our behalf.
  Future<void> _enableLocation() async {
    if (_locationBlocked) {
      await openAppSettings();
      return;
    }
    await _locate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: ScreenHeader.tab(
        title: 'sucursales'.tr(),
        // Filtering drops the focus with it: holding the camera on a branch the
        // list no longer contains leaves the map pointing at nothing the
        // customer can see, and a highlight with no row to sit on.
        onSearchChanged: (value) => setState(() {
          _query = value;
          _focused = null;
        }),
        trailing: const BrandContactAction(),
      ),
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
                .toList();

            // Knowing where the customer stands changes what the right order
            // is: proximity beats whatever sequence the backend stored. A
            // branch the backend has no coordinates for sinks to the end
            // rather than pretending to be next door.
            if (_here != null) {
              branches.sort((first, second) {
                final firstKm = _distanceTo(first);
                final secondKm = _distanceTo(second);
                if (firstKm == null) {
                  return secondKm == null ? 0 : 1;
                }
                if (secondKm == null) {
                  return -1;
                }
                return firstKm.compareTo(secondKm);
              });
            }
            // Only crown the nearest of everything. Inside a search result the
            // claim would be true of the filter, not of the network.
            final nearest = query.isEmpty &&
                    branches.length > 1 &&
                    _distanceTo(branches.first) != null
                ? branches.first.registroId
                : null;

            return Column(
              children: [
                BrandManifestReveal(
                  child: BranchMap(
                    branches: branches,
                    focused: _focused,
                    here: _here,
                    showMyLocation: !_locationRefused,
                    // A marker is already the branch's position, so tapping it
                    // has nothing to frame; what it can still offer is the sheet.
                    onSelect: _openBranch,
                  ),
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
                        if (_here == null && _locationRefused)
                          BrandManifestReveal(
                            delay: brandManifestDelay(1),
                            child: _LocationInvite(onEnable: _enableLocation),
                          ),
                        if (branches.isEmpty)
                          BrandManifestReveal(
                            delay: brandManifestDelay(1),
                            child: const BrandEmptyState(
                              messageKey: 'no_resultados',
                              glyph: BrandIcons.branches,
                            ),
                          )
                        else
                          BranchList(
                            children: [
                              for (var index = 0;
                                  index < branches.length;
                                  index++)
                                BrandManifestReveal(
                                  key: ValueKey(branches[index].registroId),
                                  delay: brandManifestDelay(
                                    index,
                                    startMilliseconds: 110,
                                  ),
                                  child: BranchRow(
                                    branch: branches[index],
                                    distanceKm: _distanceTo(branches[index]),
                                    nearest:
                                        branches[index].registroId == nearest,
                                    focused: branches[index].registroId ==
                                        _focused?.registroId,
                                    onTap: () => _focusBranch(branches[index]),
                                    onMore: () => _openBranch(branches[index]),
                                  ),
                                ),
                            ],
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

  double? _distanceTo(Sucursal branch) {
    final here = _here;
    if (here == null || (branch.latitud == 0 && branch.longitud == 0)) {
      return null;
    }
    return _haversineKm(
      here.latitude,
      here.longitude,
      branch.latitud,
      branch.longitud,
    );
  }

  /// Frames the branch on the map, or lets it go when it is already framed.
  ///
  /// This is the whole result of tapping a row, which is what makes the camera
  /// flight worth watching: nothing rises to cover it. The toggle is what keeps
  /// the gesture reversible — the same tap that went in gets you back out.
  void _focusBranch(Sucursal branch) {
    setState(
      () =>
          _focused = _focused?.registroId == branch.registroId ? null : branch,
    );
  }

  Future<void> _openBranch(Sucursal branch) async {
    final whatsapp = _profile?.whatsappSucursal ?? '';
    await showBrandSheet<void>(
      context,
      scrollable: true,
      child: BranchSheet(
        branch: branch,
        whatsapp: whatsapp,
        distanceKm: _distanceTo(branch),
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

/// Way back in after the location permission was turned down.
///
/// A refusal used to end the conversation: no distances, no ordering, and no
/// hint that either had ever been on offer. This says what is missing and gives
/// the one control that restores it.
class _LocationInvite extends StatelessWidget {
  const _LocationInvite({required this.onEnable});

  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return BrandCard(
      color: tokens.surfaceAlt,
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BrandGlyphTile(asset: BrandIcons.mapMarker, glyphSize: 18),
          const SizedBox(width: BrandSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ubicacion_para_cercania'.tr(),
                  style: tokens.body(12, color: tokens.textMuted, height: 1.4),
                ),
                const SizedBox(height: BrandSpace.xs),
                BrandOutlineButton(
                  label: 'activar_ubicacion'.tr(),
                  expand: false,
                  pill: true,
                  fontSize: 12,
                  verticalPadding: 8,
                  onPressed: onEnable,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
