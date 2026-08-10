import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design_system/brand_states.dart';
import '../design_system/core_components.dart';
import '../theme/brand_config.dart';
import 'bloc/prealertas_bloc.dart';

class PrealertasRealizadas extends StatefulWidget {
  const PrealertasRealizadas({super.key});

  @override
  State<PrealertasRealizadas> createState() => _PrealertasRealizadasState();
}

class _PrealertasRealizadasState extends State<PrealertasRealizadas> {
  late final PrealertasBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = PrealertasBloc()..add(LoadPreAlertasEvent());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ScreenHeader(title: 'prealertas'.tr()),
      body: BlocProvider.value(
        value: _bloc,
        child: BlocBuilder<PrealertasBloc, PrealertasState>(
          builder: (context, state) {
            if (state is PrealertasLoadingState) {
              return const BrandSkeleton();
            }
            if (state is PrealertasErrorState) {
              return BrandErrorState(
                onRetry: () => _bloc.add(LoadPreAlertasEvent()),
              );
            }
            if (state is! PrealertasLoadedState || state.prealertas.isEmpty) {
              return const BrandEmptyState(
                messageKey: 'no_prealertas_recientes',
              );
            }
            final currency = GetIt.I<BrandConfig>().currency;
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.prealertas.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final alert = state.prealertas[index];
                return Card(
                  child: ListTile(
                    title: Text(alert.tracking),
                    subtitle: Text(
                      [alert.enviaNombre, alert.contenido, alert.fechaEntrega]
                          .where((value) => value.isNotEmpty)
                          .join('\n'),
                    ),
                    trailing: Text('$currency ${alert.fob.toStringAsFixed(2)}'),
                    onTap: alert.facturaUrl.isEmpty
                        ? null
                        : () {
                            final uri = Uri.tryParse(alert.facturaUrl);
                            if (uri != null &&
                                (uri.scheme == 'https' ||
                                    uri.scheme == 'http')) {
                              launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
