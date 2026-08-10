import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../design_system/brand_states.dart';
import '../design_system/core_components.dart';
import '../navigation/app_routes.dart';
import 'bloc/historia_bloc.dart';

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
    return Scaffold(
      appBar: ScreenHeader(title: 'consulta_historica'.tr()),
      body: BlocProvider.value(
        value: _bloc,
        child: BlocBuilder<HistoriaBloc, HistoriaState>(
          builder: (context, state) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _DateButton(
                      label: 'desde'.tr(),
                      date: _from,
                      onTap: () => _pickDate(isFrom: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateButton(
                      label: 'hasta'.tr(),
                      date: _to,
                      onTap: () => _pickDate(isFrom: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: state is HistoriaLoadingState
                    ? null
                    : () => _bloc.add(LoadApiEvent(_from, _to)),
                icon: const Icon(Icons.search),
                label: Text('buscar'.tr()),
              ),
              const SizedBox(height: 20),
              if (state is HistoriaLoadingState)
                const BrandSkeleton()
              else if (state is HistoriaLoadedState)
                for (final package in state.recepciones) ...[
                  PackageCard(
                    package: package,
                    onTap: () => context.push(
                      AppRoutes.package(package.recepcionID),
                    ),
                  ),
                  const SizedBox(height: 12),
                ]
              else
                const BrandEmptyState(
                  messageKey: 'especifique_fechas_toque_buscar',
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

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.calendar_today_outlined),
      label: Text('$label\n${DateFormat.yMd().format(date)}'),
    );
  }
}
