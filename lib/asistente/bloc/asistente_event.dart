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
