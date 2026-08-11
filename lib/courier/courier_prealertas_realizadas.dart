import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design_system/brand_foundations.dart';
import '../design_system/brand_states.dart';
import '../design_system/core_components.dart';
import '../navigation/app_routes.dart';
import '../design_system/overlay_components.dart';
import '../services/model/prealerta_model.dart';
import '../theme/brand_tokens.dart';
import 'bloc/prealertas_bloc.dart';

/// FOB is declared in US dollars whatever currency the brand quotes in, the
/// same way the calculator labels it.
///
/// Empty when there is none to declare: automatic pre-alerts are raised by the
/// operation without a value, and a column of `US$0.00` would say nothing.
String _fob(PreAlertaDto alert) =>
    alert.fob <= 0 ? '' : 'US\$${alert.fob.toStringAsFixed(2)}';

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
    final tokens = context.brand;
    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: ScreenHeader(
        title: 'ver_prealertas'.tr().replaceAll('\n', ' '),
        titleSize: 18,
        onBack: context.popOrHome,
      ),
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
                glyph: BrandIcons.prealert,
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                BrandSpace.lg,
                BrandSpace.md,
                BrandSpace.lg,
                BrandTabBar.height,
              ),
              itemCount: state.prealertas.length,
              itemBuilder: (context, index) {
                final alert = state.prealertas[index];
                return BrandCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 13,
                  ),
                  onTap: () => _openDetail(alert),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              alert.enviaNombre.isEmpty
                                  ? alert.tracking
                                  : alert.enviaNombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tokens.body(13, weight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: BrandSpace.xs),
                          Text(
                            alert.fechaEntrega,
                            style: tokens.body(11, color: tokens.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Expanded(
                            child: Text(
                              [alert.tracking, alert.contenido]
                                  .where((value) => value.isNotEmpty)
                                  .join(' · '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: tokens.body(12, color: tokens.textMuted),
                            ),
                          ),
                          if (_fob(alert).isNotEmpty) ...[
                            const SizedBox(width: BrandSpace.xs),
                            Text(
                              _fob(alert),
                              style: tokens.body(13, weight: FontWeight.w700),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _openDetail(PreAlertaDto alert) async {
    await showBrandSheet<void>(
      context,
      scrollable: true,
      child: _PrealertaSheet(alert: alert),
    );
  }
}

/// Read-only view of a submitted pre-alert (spec §3.1).
class _PrealertaSheet extends StatelessWidget {
  const _PrealertaSheet({required this.alert});

  final PreAlertaDto alert;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return BrandSheet(
      title: alert.enviaNombre.isEmpty ? alert.tracking : alert.enviaNombre,
      subtitle: alert.fechaEntrega,
      maxHeightFactor: 0.8,
      children: [
        _Field(label: 'transportista'.tr(), value: alert.enviaNombre),
        _Field(label: 'numero_rastreo'.tr(), value: alert.tracking),
        _Field(label: 'contenido'.tr(), value: alert.contenido),
        _Field(label: 'valor_fob'.tr(), value: _fob(alert)),
        if (alert.comentario.isNotEmpty)
          _Field(label: 'otro'.tr(), value: alert.comentario),
        if (alert.facturaUrl.isNotEmpty) ...[
          const SizedBox(height: BrandSpace.xs),
          BrandOutlineButton(
            label: 'ver_factura'.tr(),
            foreground: tokens.primary,
            onPressed: () {
              final uri = Uri.tryParse(alert.facturaUrl);
              if (uri != null &&
                  (uri.scheme == 'https' || uri.scheme == 'http')) {
                launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: BrandSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: tokens.body(
              11,
              weight: FontWeight.w600,
              color: tokens.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: tokens.body(14, weight: FontWeight.w500)),
        ],
      ),
    );
  }
}
