import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design_system/brand_states.dart';
import '../design_system/content_components.dart';
import '../design_system/core_components.dart';
import '../services/courier_service.dart';
import '../services/model/sucursal.dart';
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

  @override
  void initState() {
    super.initState();
    _bloc = SucursalesBloc(GetIt.I<CourierService>())
      ..add(const LoadApiEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ScreenHeader(title: 'sucursales'.tr()),
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
              return const BrandEmptyState(messageKey: 'no_resultados');
            }
            final branches = state.sucursales.where((branch) {
              final query = _query.toLowerCase();
              return query.isEmpty ||
                  branch.nombre.toLowerCase().contains(query) ||
                  branch.ciudad.toLowerCase().contains(query) ||
                  branch.direccion.toLowerCase().contains(query);
            }).toList(growable: false);
            return RefreshIndicator(
              onRefresh: () async =>
                  _bloc.add(const LoadApiEvent(ignoreCache: true)),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  SearchBar(
                    controller: _searchController,
                    hintText: 'buscar'.tr(),
                    leading: const Icon(Icons.search),
                    trailing: [
                      if (_query.isNotEmpty)
                        IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.clear),
                        ),
                    ],
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 16),
                  if (branches.isNotEmpty) ...[
                    BranchMap(branches: branches),
                    const SizedBox(height: 16),
                  ],
                  if (branches.isEmpty)
                    const BrandEmptyState(messageKey: 'no_resultados')
                  else
                    for (final branch in branches) ...[
                      BranchCard(
                        branch: branch,
                        onCall: branch.telefonoOficina.isEmpty
                            ? null
                            : () => _launchPhone(branch.telefonoOficina),
                        onWhatsApp: branch.telefonoVentas.isEmpty
                            ? null
                            : () => _launchWhatsApp(branch.telefonoVentas),
                        onDirections: () => _launchDirections(branch),
                      ),
                      const SizedBox(height: 12),
                    ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _launchPhone(String phone) =>
      launchUrl(Uri(scheme: 'tel', path: phone));

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
