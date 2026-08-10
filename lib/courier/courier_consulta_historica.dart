import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../design_system/brand_foundations.dart';
import '../design_system/brand_states.dart';
import '../design_system/core_components.dart';
import '../navigation/app_routes.dart';
import '../theme/brand_tokens.dart';
import 'bloc/historia_bloc.dart';

/// Same package list as receptions, filtered by a date range.
class ConsultaHistoricaPage extends StatefulWidget {
  const ConsultaHistoricaPage({super.key});

  @override
  State<ConsultaHistoricaPage> createState() => _ConsultaHistoricaPageState();
}

class _ConsultaHistoricaPageState extends State<ConsultaHistoricaPage> {
  late final HistoriaBloc _bloc;
  DateTime _from = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to = DateTime.now();

  @override
  void initState() {
    super.initState();
    _bloc = HistoriaBloc(HistoriaIdleState());
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
        title: 'consulta_historica'.tr().replaceAll('\n', ' '),
        titleSize: 18,
        onBack: context.canPop() ? context.pop : null,
      ),
      body: BlocProvider.value(
        value: _bloc,
        child: BlocBuilder<HistoriaBloc, HistoriaState>(
          builder: (context, state) => ListView(
            padding: const EdgeInsets.fromLTRB(
              BrandSpace.lg,
              18,
              BrandSpace.lg,
              BrandTabBar.height,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'desde'.tr(),
                      date: _from,
                      onTap: () => _pickDate(isFrom: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DateField(
                      label: 'hasta'.tr(),
                      date: _to,
                      onTap: () => _pickDate(isFrom: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: BrandSpace.md),
              BrandPrimaryButton(
                label: 'buscar'.tr(),
                onPressed: state is HistoriaLoadingState
                    ? null
                    : () => _bloc.add(LoadApiEvent(_from, _to)),
              ),
              const SizedBox(height: 14),
              if (state is HistoriaLoadingState)
                const BrandSkeleton()
              else if (state is HistoriaLoadedState)
                if (state.recepciones.isEmpty)
                  const BrandEmptyState(
                    messageKey: 'no_paquetes',
                    glyph: BrandIcons.history,
                  )
                else
                  for (final package in state.recepciones)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 11),
                      child: PackageCard(
                        package: package,
                        onTap: () => context.push(
                          AppRoutes.package(package.recepcionID),
                        ),
                      ),
                    )
              else
                const BrandEmptyState(
                  messageKey: 'especifique_fechas_toque_buscar',
                  glyph: BrandIcons.history,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: isFrom ? _from : _to,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (selected == null) {
      return;
    }
    setState(() {
      if (isFrom) {
        _from = selected;
        if (_to.isBefore(_from)) _to = _from;
      } else {
        _to = selected;
        if (_from.isAfter(_to)) _from = _to;
      }
    });
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return BrandCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: tokens.eyebrow(10)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('dd-MMM-yyyy').format(date),
                  style: tokens.head(15),
                ),
              ),
              Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: tokens.textMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
