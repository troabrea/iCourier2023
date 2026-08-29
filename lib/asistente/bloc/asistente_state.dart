part of 'asistente_bloc.dart';

/// Why the last question produced no answer.
enum AssistantFailure {
  /// The session ended while the screen was open.
  signedOut,

  /// The webhook could not be reached or answered with nothing.
  unavailable,
}

/// Everything the assistant screen draws.
///
/// One state class rather than a hierarchy: the screen always shows the same
/// three regions — the ribbon of past questions, the current document, and the
/// composer — and only their contents change. Splitting that into loading,
/// loaded and error classes would force every region to be rebuilt from
/// scratch in each branch.
final class AsistenteState extends Equatable {
  const AsistenteState({
    this.turns = const [],
    this.selectedIndex = -1,
    this.pendingQuestion,
    this.failure,
    this.failedQuestion,
    this.quotaScope,
    this.quotaResetAt,
    this.quotaRequestId,
    this.justAnswered = false,
  });

  final List<AssistantTurn> turns;

  /// Index into [turns] of the answer on screen; -1 before the first answer.
  final int selectedIndex;

  /// The question currently being answered, if any.
  final String? pendingQuestion;

  final AssistantFailure? failure;

  /// The question [AssistantRetryRequested] would send again.
  final String? failedQuestion;

  /// Which server-side allowance is spent, or null while questions are open.
  final AssistantQuotaScope? quotaScope;

  /// When the spent allowance resets, if the proxy supplied it.
  final DateTime? quotaResetAt;

  /// Correlates the refusal with the proxy's logs.
  final String? quotaRequestId;

  /// True only on the state that carries a newly arrived answer.
  ///
  /// The arrival reveal is the one authored moment on this surface, so it must
  /// not replay every time the customer taps back to an answer they have
  /// already read.
  final bool justAnswered;

  bool get isAsking => pendingQuestion != null;

  bool get hasSpentQuota => quotaScope != null;

  bool get hasConversation => turns.isNotEmpty;

  AssistantTurn? get selected =>
      selectedIndex >= 0 && selectedIndex < turns.length
          ? turns[selectedIndex]
          : null;

  AsistenteState copyWith({
    List<AssistantTurn>? turns,
    int? selectedIndex,
    String? pendingQuestion,
    bool clearPending = false,
    AssistantFailure? failure,
    bool clearFailure = false,
    String? failedQuestion,
    AssistantQuotaScope? quotaScope,
    DateTime? quotaResetAt,
    String? quotaRequestId,
    bool justAnswered = false,
  }) =>
      AsistenteState(
        turns: turns ?? this.turns,
        selectedIndex: selectedIndex ?? this.selectedIndex,
        pendingQuestion:
            clearPending ? null : pendingQuestion ?? this.pendingQuestion,
        failure: clearFailure ? null : failure ?? this.failure,
        failedQuestion:
            clearFailure ? null : failedQuestion ?? this.failedQuestion,
        quotaScope: quotaScope ?? this.quotaScope,
        quotaResetAt: quotaResetAt ?? this.quotaResetAt,
        quotaRequestId: quotaRequestId ?? this.quotaRequestId,
        justAnswered: justAnswered,
      );

  @override
  List<Object?> get props => [
        turns.length,
        selectedIndex,
        pendingQuestion,
        failure,
        failedQuestion,
        quotaScope,
        quotaResetAt,
        quotaRequestId,
        justAnswered,
      ];
}
