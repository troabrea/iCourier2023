import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../design_system/brand_states.dart';
import '../design_system/content_components.dart';
import '../design_system/core_components.dart';
import '../services/courier_service.dart';
import 'bloc/preguntas_bloc.dart';

class PreguntasPage extends StatefulWidget {
  const PreguntasPage({super.key});

  @override
  State<PreguntasPage> createState() => _PreguntasPageState();
}

class _PreguntasPageState extends State<PreguntasPage> {
  late final PreguntasBloc _bloc;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _bloc = PreguntasBloc(GetIt.I<CourierService>())..add(const LoadApiEvent());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ScreenHeader(title: 'preguntas'.tr()),
      body: BlocProvider.value(
        value: _bloc,
        child: BlocBuilder<PreguntasBloc, PreguntasState>(
          builder: (context, state) {
            if (state is PreguntasLoadingState) {
              return const BrandSkeleton();
            }
            if (state is PreguntasErrorState) {
              return BrandErrorState(
                onRetry: () => _bloc.add(const LoadApiEvent(ignoreCache: true)),
              );
            }
            if (state is! PreguntasLoadedState) {
              return const BrandEmptyState(messageKey: 'no_resultados');
            }
            final questions = state.preguntas.where((question) {
              final query = _query.toLowerCase();
              return query.isEmpty ||
                  question.titulo.toLowerCase().contains(query) ||
                  question.resumen.toLowerCase().contains(query);
            }).toList(growable: false);
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SearchBar(
                  hintText: 'buscar'.tr(),
                  leading: const Icon(Icons.search),
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 16),
                if (questions.isEmpty)
                  const BrandEmptyState(messageKey: 'no_resultados')
                else
                  for (final question in questions) ...[
                    FaqAccordion(
                      question: question.titulo,
                      answer: question.resumen,
                    ),
                    const SizedBox(height: 8),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }
}
