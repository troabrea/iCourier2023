import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../design_system/brand_foundations.dart';
import '../design_system/brand_states.dart';
import '../design_system/content_components.dart';
import '../design_system/core_components.dart';
import '../navigation/app_routes.dart';
import '../services/courier_service.dart';
import '../theme/brand_tokens.dart';
import 'bloc/preguntas_bloc.dart';

class PreguntasPage extends StatefulWidget {
  const PreguntasPage({super.key});

  @override
  State<PreguntasPage> createState() => _PreguntasPageState();
}

class _PreguntasPageState extends State<PreguntasPage> {
  late final PreguntasBloc _bloc;

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
    final tokens = context.brand;
    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: ScreenHeader(
        title: 'preguntas'.tr(),
        onBack: context.popOrHome,
      ),
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
            if (state is! PreguntasLoadedState || state.preguntas.isEmpty) {
              return const BrandEmptyState(
                messageKey: 'no_resultados',
                glyph: BrandIcons.questions,
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                BrandSpace.lg,
                BrandSpace.md,
                BrandSpace.lg,
                BrandTabBar.height,
              ),
              itemCount: state.preguntas.length,
              itemBuilder: (context, index) => FaqAccordion(
                question: state.preguntas[index].titulo,
                answer: state.preguntas[index].resumen,
                initiallyExpanded: index == 0,
              ),
            );
          },
        ),
      ),
    );
  }
}
