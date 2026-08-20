import 'package:flutter/foundation.dart';

/// Who the assistant is answering for.
///
/// The webhook has no user directory of its own: every request carries the
/// company, the live courier session and the customer's home branch, and the
/// backend resolves the customer's packages from those. An identity missing
/// either the session or the account cannot be answered, which is why
/// [isSignedIn] gates the whole surface.
@immutable
final class AssistantIdentity {
  const AssistantIdentity({
    required this.empresaId,
    required this.sessionId,
    required this.firstName,
    required this.lastName,
    required this.userAccount,
    required this.sucursalId,
  });

  final String empresaId;
  final String sessionId;
  final String firstName;
  final String lastName;
  final String userAccount;
  final String sucursalId;

  bool get isSignedIn => sessionId.isNotEmpty && userAccount.isNotEmpty;

  Map<String, dynamic> requestBody(String question) => {
        'empresaId': empresaId,
        'sessionId': sessionId,
        'firstName': firstName,
        'lastName': lastName,
        'userAccount': userAccount,
        'sucursalId': sucursalId,
        'question': question,
      };
}

/// Splits the single stored display name into the two fields the webhook wants.
///
/// The session only ever returns `nombre` as one string, so the first word is
/// taken as the given name and whatever follows as the family name. A single
/// word stays the given name rather than being duplicated, and the surrounding
/// whitespace of a hand-typed record is collapsed instead of being sent on.
({String firstName, String lastName}) splitCustomerName(String fullName) {
  final parts = fullName
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) {
    return (firstName: '', lastName: '');
  }
  return (
    firstName: parts.first,
    lastName: parts.skip(1).join(' '),
  );
}

/// What the webhook sent back for one question.
///
/// The workflow decides whether the exchange should reach a person: it knows
/// whether its own tools came up empty and whether the customer is asking for
/// one. The app never second-guesses that flag, it only acts on it.
@immutable
final class AssistantReply {
  const AssistantReply({
    required this.text,
    this.needsHuman = false,
    this.summary = '',
  });

  /// Markdown as the webhook returned it. Rendering belongs to the surface.
  final String text;

  /// Whether this exchange should be handed to a person.
  final bool needsHuman;

  /// The customer's own words for that person, written in the first person so
  /// it can be sent as the opening WhatsApp message without being rewritten.
  final String summary;

  /// A handoff is only offerable when there is something to say.
  bool get hasHandoff => needsHuman && summary.trim().isNotEmpty;
}

/// One question and the reply it produced.
@immutable
final class AssistantTurn {
  const AssistantTurn({required this.question, required this.reply});

  final String question;
  final AssistantReply reply;

  String get answer => reply.text;
}
