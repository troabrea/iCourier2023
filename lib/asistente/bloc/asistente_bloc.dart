import 'dart:async';

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
    on<_AssistantStreamUpdate>(_onStreamUpdate);
    on<_AssistantStreamFailed>(_onStreamFailed);
    on<_AssistantStreamClosed>(_onStreamClosed);
    on<_AssistantStreamFlushed>(_onStreamFlushed);
  }

  final AssistantService _assistant;
  final AssistantConversation _conversation;
  StreamSubscription<AssistantStreamEvent>? _activeRequest;
  Timer? _renderTimer;
  int _lastRequestId = 0;
  int? _activeRequestId;
  String _activeQuestion = '';
  String _renderedAnswer = '';
  String _queuedAnswer = '';
  bool _receivedText = false;

  /// Caps markdown parsing and painting while tokens arrive rapidly.
  static const Duration _streamFrame = Duration(milliseconds: 50);

  @override
  Future<void> close() {
    final request = _activeRequest;
    _activeRequest = null;
    _activeRequestId = null;
    _renderTimer?.cancel();
    _renderTimer = null;
    request?.cancel().ignore();
    return super.close();
  }

  void _onAsked(
    AssistantQuestionAsked event,
    Emitter<AsistenteState> emit,
  ) {
    final question = event.question.trim();
    if (question.isEmpty || state.isAsking || state.hasSpentQuota) {
      return;
    }
    _startRequest(question, emit);
  }

  void _onRetry(
    AssistantRetryRequested event,
    Emitter<AsistenteState> emit,
  ) {
    final question = state.failedQuestion;
    if (question == null || state.isAsking || state.hasSpentQuota) {
      return;
    }
    _startRequest(question, emit);
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

  void _startRequest(String question, Emitter<AsistenteState> emit) {
    emit(
      state.copyWith(
        pendingQuestion: question,
        clearFailure: true,
        clearStreaming: true,
      ),
    );

    final requestId = ++_lastRequestId;
    _activeRequestId = requestId;
    _activeQuestion = question;
    _renderedAnswer = '';
    _queuedAnswer = '';
    _receivedText = false;

    _activeRequest = _assistant.askStream(question).listen(
          (event) => _addIfActive(
            requestId,
            _AssistantStreamUpdate(requestId, event),
          ),
          onError: (Object error, StackTrace stackTrace) => _addIfActive(
            requestId,
            _AssistantStreamFailed(requestId, error),
          ),
          onDone: () => _addIfActive(
            requestId,
            _AssistantStreamClosed(requestId),
          ),
          cancelOnError: true,
        );
  }

  void _onStreamUpdate(
    _AssistantStreamUpdate update,
    Emitter<AsistenteState> emit,
  ) {
    if (update.requestId != _activeRequestId) {
      return;
    }
    switch (update.event) {
      case AssistantStreamStatus(:final code):
        emit(state.copyWith(streamingStatus: code));
      case AssistantTextDelta(:final text):
        if (text.isEmpty) {
          return;
        }
        _receivedText = true;
        _queuedAnswer += text;
        if (_renderedAnswer.isEmpty) {
          _flushStream(emit);
        } else {
          _renderTimer ??= Timer(_streamFrame, () {
            _renderTimer = null;
            _addIfActive(
              update.requestId,
              _AssistantStreamFlushed(update.requestId),
            );
          });
        }
      case AssistantReplyCompleted(:final reply):
        if (reply.text.trim().isEmpty) {
          _finishWithFailure(
            update.requestId,
            const AssistantUnavailableException(),
            emit,
          );
          return;
        }
        _stopRequest();
        final turns = [
          ...state.turns,
          AssistantTurn(question: _activeQuestion, reply: reply),
        ];
        emit(
          state.copyWith(
            turns: turns,
            selectedIndex: turns.length - 1,
            clearPending: true,
            clearStreaming: true,
            justAnswered: !_receivedText,
          ),
        );
        _keep();
    }
  }

  void _onStreamFailed(
    _AssistantStreamFailed event,
    Emitter<AsistenteState> emit,
  ) {
    if (event.requestId != _activeRequestId) {
      return;
    }
    _finishWithFailure(event.requestId, event.error, emit);
  }

  void _onStreamClosed(
    _AssistantStreamClosed event,
    Emitter<AsistenteState> emit,
  ) {
    if (event.requestId != _activeRequestId) {
      return;
    }
    _finishWithFailure(
      event.requestId,
      const AssistantUnavailableException(),
      emit,
    );
  }

  void _onStreamFlushed(
    _AssistantStreamFlushed event,
    Emitter<AsistenteState> emit,
  ) {
    if (event.requestId == _activeRequestId) {
      _flushStream(emit);
    }
  }

  void _flushStream(Emitter<AsistenteState> emit) {
    if (_queuedAnswer.isEmpty) {
      return;
    }
    _renderedAnswer += _queuedAnswer;
    _queuedAnswer = '';
    emit(
      state.copyWith(
        streamingAnswer: _renderedAnswer,
        streamingStatus: '',
      ),
    );
  }

  void _finishWithFailure(
    int requestId,
    Object error,
    Emitter<AsistenteState> emit,
  ) {
    if (requestId != _activeRequestId) {
      return;
    }
    final question = _activeQuestion;
    _stopRequest();
    switch (error) {
      case AssistantSignedOutException():
        emit(
          state.copyWith(
            clearPending: true,
            clearStreaming: true,
            failure: AssistantFailure.signedOut,
            failedQuestion: question,
          ),
        );
      case AssistantQuotaException():
        emit(
          state.copyWith(
            clearPending: true,
            clearStreaming: true,
            clearFailure: true,
            quotaScope: error.scope,
            quotaResetAt: error.resetAt,
            quotaRequestId: error.requestId,
          ),
        );
      default:
        emit(
          state.copyWith(
            clearPending: true,
            clearStreaming: true,
            failure: AssistantFailure.unavailable,
            failedQuestion: question,
          ),
        );
    }
  }

  void _stopRequest() {
    final request = _activeRequest;
    _activeRequest = null;
    _activeRequestId = null;
    _renderTimer?.cancel();
    _renderTimer = null;
    request?.cancel().ignore();
    _renderedAnswer = '';
    _queuedAnswer = '';
  }

  void _addIfActive(int requestId, AsistenteEvent event) {
    if (!isClosed && requestId == _activeRequestId) {
      add(event);
    }
  }

  /// Hands the conversation back to the store after every change to it.
  void _keep() => _conversation.remember(
        turns: state.turns,
        selectedIndex: state.selectedIndex,
      );
}
