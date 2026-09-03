part of 'asistente_bloc.dart';

sealed class AsistenteEvent extends Equatable {
  const AsistenteEvent();

  @override
  List<Object?> get props => const [];
}

/// The customer sent a question, from the composer or a starter suggestion.
final class AssistantQuestionAsked extends AsistenteEvent {
  const AssistantQuestionAsked(this.question);

  final String question;

  @override
  List<Object?> get props => [question];
}

/// The customer picked an earlier exchange from the ribbon.
final class AssistantAnswerSelected extends AsistenteEvent {
  const AssistantAnswerSelected(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}

/// Sends the question that failed once more, unchanged.
final class AssistantRetryRequested extends AsistenteEvent {
  const AssistantRetryRequested();
}

/// The customer asked to start over.
final class AssistantConversationCleared extends AsistenteEvent {
  const AssistantConversationCleared();
}

final class _AssistantStreamUpdate extends AsistenteEvent {
  const _AssistantStreamUpdate(this.requestId, this.event);

  final int requestId;
  final AssistantStreamEvent event;
}

final class _AssistantStreamFailed extends AsistenteEvent {
  const _AssistantStreamFailed(this.requestId, this.error);

  final int requestId;
  final Object error;
}

final class _AssistantStreamClosed extends AsistenteEvent {
  const _AssistantStreamClosed(this.requestId);

  final int requestId;
}

final class _AssistantStreamFlushed extends AsistenteEvent {
  const _AssistantStreamFlushed(this.requestId);

  final int requestId;
}
