import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../services/assistant_service.dart';
import '../../services/model/asistente_model.dart';
import '../assistant_conversation.dart';

part 'asistente_event.dart';
part 'asistente_state.dart';

/// Drives one customer's conversation with the assistant.
///
/// The turns themselves belong to [AssistantConversation], which outlives this
/// screen, so following a shortcut into another tab and coming back resumes the
/// conversation instead of starting over. Nothing is written to disk either
/// way: it ends with the process, or with the session, whichever comes first.
class AsistenteBloc extends Bloc<AsistenteEvent, AsistenteState> {
  AsistenteBloc(AssistantService assistant, AssistantConversation conversation)
      : _assistant = assistant,
        _conversation = conversation,
        super(
          AsistenteState(
            turns: conversation.turns,
            selectedIndex: conversation.selectedIndex,
          ),
        ) {
    on<AssistantQuestionAsked>(_onAsked);
    on<AssistantAnswerSelected>(_onSelected);
    on<AssistantRetryRequested>(_onRetry);
    on<AssistantConversationCleared>(_onCleared);
  }

  final AssistantService _assistant;
  final AssistantConversation _conversation;

  Future<void> _onAsked(
    AssistantQuestionAsked event,
    Emitter<AsistenteState> emit,
  ) async {
    final question = event.question.trim();
    if (question.isEmpty || state.isAsking || state.hasSpentQuota) {
      return;
    }
    await _ask(question, emit);
  }

  Future<void> _onRetry(
    AssistantRetryRequested event,
    Emitter<AsistenteState> emit,
  ) async {
    final question = state.failedQuestion;
    if (question == null || state.isAsking || state.hasSpentQuota) {
      return;
    }
    await _ask(question, emit);
  }

  void _onCleared(
    AssistantConversationCleared event,
    Emitter<AsistenteState> emit,
  ) {
    if (state.isAsking) {
      return;
    }
    _conversation.clear();
    emit(
      AsistenteState(
        quotaScope: state.quotaScope,
        quotaResetAt: state.quotaResetAt,
        quotaRequestId: state.quotaRequestId,
      ),
    );
  }

  void _onSelected(
    AssistantAnswerSelected event,
    Emitter<AsistenteState> emit,
  ) {
    if (event.index < 0 || event.index >= state.turns.length) {
      return;
    }
    emit(state.copyWith(selectedIndex: event.index));
    _keep();
  }

  /// Hands the conversation back to the store after every change to it.
  void _keep() => _conversation.remember(
        turns: state.turns,
        selectedIndex: state.selectedIndex,
      );

  Future<void> _ask(String question, Emitter<AsistenteState> emit) async {
    emit(
      state.copyWith(
        pendingQuestion: question,
        clearFailure: true,
      ),
    );
    try {
      final reply = await _assistant.ask(question);
      final turns = [
        ...state.turns,
        AssistantTurn(question: question, reply: reply),
      ];
      emit(
        state.copyWith(
          turns: turns,
          selectedIndex: turns.length - 1,
          clearPending: true,
          justAnswered: true,
        ),
      );
      _keep();
    } on AssistantSignedOutException {
      emit(
        state.copyWith(
          clearPending: true,
          failure: AssistantFailure.signedOut,
          failedQuestion: question,
        ),
      );
    } on AssistantQuotaException catch (error) {
      emit(
        state.copyWith(
          clearPending: true,
          clearFailure: true,
          quotaScope: error.scope,
          quotaResetAt: error.resetAt,
          quotaRequestId: error.requestId,
        ),
      );
    } on AssistantUnavailableException {
      emit(
        state.copyWith(
          clearPending: true,
          failure: AssistantFailure.unavailable,
          failedQuestion: question,
        ),
      );
    }
  }
}
