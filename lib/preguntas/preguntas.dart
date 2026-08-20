import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../design_system/brand_foundations.dart';
import '../design_system/brand_states.dart';
import '../design_system/content_components.dart';
import '../design_system/core_components.dart';
import '../design_system/motion_components.dart';
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
    final tokens = context.brand;
    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: ScreenHeader(
        title: 'preguntas_frecuentes'.tr(),
        onBack: context.popOrHome,
        onSearchChanged: (value) => setState(() => _query = value.trim()),
        searchHint: 'buscar_preguntas'.tr(),
      ),
      body: BlocProvider.value(
        value: _bloc,
        child: BlocBuilder<PreguntasBloc, PreguntasState>(
          builder: (context, state) {
            if (state is PreguntasLoadingState) {
              return const BrandSkeleton();
            }
            if (state is PreguntasErrorState) {
              return BrandErrorState(onRetry: _refresh);
            }
            if (state is! PreguntasLoadedState) {
              return const SizedBox.shrink();
            }
            final normalizedQuery = _query.toLowerCase();
            final questions = state.preguntas.where((question) {
              if (normalizedQuery.isEmpty) {
                return true;
              }
              return question.titulo.toLowerCase().contains(normalizedQuery) ||
                  question.resumen.toLowerCase().contains(normalizedQuery);
            }).toList();
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  BrandSpace.lg,
                  BrandSpace.md,
                  BrandSpace.lg,
                  BrandTabBar.height,
                ),
                children: [
                  BrandManifestReveal(
                    child: _QuestionsGuide(count: questions.length),
                  ),
                  const SizedBox(height: BrandSpace.md),
                  if (questions.isEmpty)
                    BrandManifestReveal(
                      delay: brandManifestDelay(1),
                      child: BrandEmptyState(
                        messageKey: normalizedQuery.isEmpty
                            ? 'no_resultados'
                            : 'sin_preguntas_coincidentes',
                        glyph: BrandIcons.questions,
                        actionLabel:
                            normalizedQuery.isEmpty ? 'actualizar'.tr() : null,
                        onAction: normalizedQuery.isEmpty ? _refresh : null,
                      ),
                    )
                  else
                    for (var index = 0; index < questions.length; index++)
                      BrandManifestReveal(
                        key: ValueKey(questions[index].registroId),
                        delay: brandManifestDelay(
                          index,
                          startMilliseconds: 80,
                        ),
                        child: FaqAccordion(
                          question: questions[index].titulo,
                          answer: questions[index].resumen,
                          initiallyExpanded: index == 0 && _query.isEmpty,
                        ),
                      ),
                  const SizedBox(height: BrandSpace.md),
                  BrandManifestReveal(
                    delay: brandManifestDelay(questions.length,
                        startMilliseconds: 80),
                    child: const _AskAssistant(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    final completed = Completer<void>();
    _bloc.add(LoadApiEvent(ignoreCache: true, completed: completed));
    await completed.future;
  }
}

/// Hands an unanswered question to the assistant.
///
/// The published questions cover what most customers ask; the ones they cannot
/// find here are exactly the ones worth asking in their own words.
class _AskAssistant extends StatelessWidget {
  const _AskAssistant();

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return BrandCard(
      onTap: () => context.push(AppRoutes.assistant),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const BrandGlyphTile(
            asset: BrandIcons.assistant,
            size: 38,
            glyphSize: 21,
          ),
          const SizedBox(width: BrandSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'preguntas_sin_respuesta'.tr(),
                  style: tokens.body(14, weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  'preguntas_abrir_asistente'.tr(),
                  style: tokens.body(12, color: tokens.textMuted, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: BrandSpace.xs),
          const BrandChevron(),
        ],
      ),
    );
  }
}

class _QuestionsGuide extends StatelessWidget {
  const _QuestionsGuide({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Semantics(
      container: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const BrandGlyphTile(
            asset: BrandIcons.questions,
            size: 44,
            glyphSize: 23,
          ),
          const SizedBox(width: BrandSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'preguntas_guia'.tr(),
                  style: tokens.body(13, weight: FontWeight.w600, height: 1.35),
                ),
                const SizedBox(height: BrandSpace.xxs),
                Text(
                  'preguntas_disponibles'.plural(count, args: ['$count']),
                  style: tokens.body(12, color: tokens.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
