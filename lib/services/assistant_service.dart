import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_cache/flutter_cache.dart' as cache;
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';

import '../apps/appinfo.dart';
import '../helpers/appcenter.dart';
import 'courier_service.dart';
import 'model/asistente_model.dart';
import 'model/assistant_settings.dart';

/// The customer is not signed in, so no question can be attributed.
final class AssistantSignedOutException implements Exception {
  const AssistantSignedOutException();
}

/// The webhook could not be reached, timed out, or answered with nothing.
final class AssistantUnavailableException implements Exception {
  const AssistantUnavailableException();
}

/// Which server-side allowance refused an assistant question.
enum AssistantQuotaScope {
  /// This customer's allowance for the current day is spent.
  sessionDaily,

  /// The courier's shared allowance for the current month is spent.
  companyMonthly,

  /// An older or malformed response did not identify the spent allowance.
  unknown,
}

/// The workflow refused the question because a quota is spent.
///
/// The caps themselves live in the courier's record and are counted by the
/// workflow. This app only reports the refusal, because a limit the client
/// counts is a limit anyone can reset by reinstalling.
final class AssistantQuotaException implements Exception {
  const AssistantQuotaException({
    this.scope = AssistantQuotaScope.unknown,
    this.resetAt,
    this.requestId,
  });

  /// Which allowance refused the question.
  final AssistantQuotaScope scope;

  /// When the allowance becomes available again, if the proxy supplied it.
  final DateTime? resetAt;

  /// The proxy's correlation id, if the refusal reached its request log.
  final String? requestId;
}

/// Reads the identity a question is asked under.
typedef AssistantIdentityReader = Future<AssistantIdentity> Function();

/// Reads the courier's own assistant configuration.
typedef AssistantSettingsReader = Future<AssistantSettings> Function();

/// Talks to the hosted assistant webhook.
///
/// The endpoint is a plain request/response call: there is no streaming and no
/// client-side thread id, because the backend keys its own memory on the
/// courier `sessionId` it already receives. Answers have been measured between
/// three and twenty-two seconds, so [timeout] is generous on purpose — cutting
/// a slow but valid answer short is worse than making the customer wait with a
/// visible state.
///
/// Nothing in here writes the question, the answer, or the identity to disk or
/// to a log. The conversation is personal data and stays in memory for as long
/// as the screen is open.
class AssistantService {
  AssistantService({
    Client? client,
    Uri? endpoint,
    AssistantIdentityReader? identity,
    AssistantSettingsReader? settings,
  })  : _client = client ?? Client(),
        _endpoint = endpoint ?? Uri.parse(defaultEndpoint),
        _identity = identity ?? readSessionIdentity,
        _settings = settings ?? readCompanySettings;

  /// Where questions go for a courier whose record names no workflow.
  ///
  /// Kept as the fallback rather than as a hard requirement so the module
  /// keeps working through the rollout, while every courier's record is still
  /// being filled in.
  static const String defaultEndpoint =
      'https://n8n.barolitcloud.dev/webhook/courier/assistant';

  static const Duration timeout = Duration(seconds: 90);

  final Client _client;
  final Uri _endpoint;
  final AssistantIdentityReader _identity;
  final AssistantSettingsReader _settings;

  /// The identity the next question would be asked under.
  ///
  /// The screen needs it before the first question, to greet the customer and
  /// to know whether there is a session at all.
  Future<AssistantIdentity> identity() => _identity();

  /// Reads the assistant record off the company the app is running as.
  ///
  /// The company record is cached, so asking for it on every question costs a
  /// read rather than a request. With no courier registered there is nothing
  /// to read and no way to fail over: the shared fallback endpoint answers,
  /// exactly as it did before the record existed.
  static Future<AssistantSettings> readCompanySettings() async {
    if (!GetIt.I.isRegistered<CourierService>()) {
      return AssistantSettings.none;
    }
    final courier = GetIt.I<CourierService>();
    try {
      await courier.getEmpresa(retryEmtpy: true);
    } on Exception {
      // A record that cannot be fetched leaves whatever was already read in
      // place, and the fallback endpoint answers meanwhile.
    }
    return courier.assistantSettings;
  }

  /// Builds the identity from the live courier session.
  static Future<AssistantIdentity> readSessionIdentity() async {
    final name = splitCustomerName(
      (await cache.load('userName', '')).toString(),
    );
    return AssistantIdentity(
      empresaId: GetIt.I<CourierService>().companyId,
      sessionId: (await cache.load('sessionId', '')).toString(),
      firstName: name.firstName,
      lastName: name.lastName,
      userAccount: (await cache.load('userAccount', '')).toString(),
      sucursalId: (await cache.load('userSucursal', '')).toString(),
    );
  }

  /// Returns the assistant's reply.
  ///
  /// Throws [AssistantSignedOutException] when there is no session to attribute
  /// the question to, [AssistantQuotaException] when the workflow refuses the
  /// question because a cap is spent, and [AssistantUnavailableException] for
  /// every transport, status, or empty-body failure the customer can only
  /// respond to by retrying.
  Future<AssistantReply> ask(String question) async {
    final asked = question.trim();
    if (asked.isEmpty) {
      throw const AssistantUnavailableException();
    }

    final identity = await _identity();
    if (!identity.isSignedIn) {
      throw const AssistantSignedOutException();
    }

    final settings = await _settings();

    if (GetIt.I.isRegistered<AppInfo>()) {
      try {
        AppCenter.trackEventAsync(
          '${GetIt.I<AppInfo>().metricsPrefixKey}_ASK_ASSISTANT',
        );
      } on Exception {
        // Metrics are never worth losing the customer's question over.
      }
    }

    Response response;
    try {
      response = await _client
          .post(
            settings.endpoint ?? _endpoint,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              if (settings.apiKey.isNotEmpty) 'X-Api-Key': settings.apiKey,
            },
            body: utf8.encode(jsonEncode(identity.requestBody(asked))),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const AssistantUnavailableException();
    } on SocketException {
      throw const AssistantUnavailableException();
    } on ClientException {
      throw const AssistantUnavailableException();
    }

    // A spent cap is the one refusal retrying cannot fix, so it is told apart
    // from the failures that a second tap does fix.
    if (response.statusCode == HttpStatus.tooManyRequests) {
      throw _readQuota(response);
    }
    if (response.statusCode == HttpStatus.paymentRequired) {
      throw const AssistantQuotaException();
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const AssistantUnavailableException();
    }

    final reply = _readReply(_decode(response));
    if (reply.text.isEmpty) {
      throw const AssistantUnavailableException();
    }
    return reply;
  }

  /// Reads the body as text.
  ///
  /// The workflow declares `charset=utf-8` today, and strict UTF-8 is the right
  /// first attempt because the answers are full of accents. But a workflow edit
  /// that drops the header would make a strict decode throw, and losing the
  /// whole answer over an encoding header is a worse outcome than losing an
  /// accent, so the declared charset gets the second attempt.
  static String _decode(Response response) {
    try {
      return utf8.decode(response.bodyBytes);
    } on FormatException {
      return response.body;
    }
  }

  /// Reads the structured refusal returned by the assistant proxy.
  ///
  /// A malformed body still means the quota is spent because the HTTP status
  /// is authoritative. It only costs the app the more specific explanation.
  static AssistantQuotaException _readQuota(Response response) {
    Object? decoded;
    try {
      decoded = jsonDecode(_decode(response));
    } on FormatException {
      return const AssistantQuotaException();
    }
    if (decoded is! Map) {
      return const AssistantQuotaException();
    }
    final error = decoded['error'];
    if (error is! Map) {
      return const AssistantQuotaException();
    }

    final scope = switch (error['scope']) {
      'session_daily' => AssistantQuotaScope.sessionDaily,
      'company_monthly' => AssistantQuotaScope.companyMonthly,
      _ => AssistantQuotaScope.unknown,
    };
    final resetAt = error['resetAt'];
    final requestId = error['requestId'];
    return AssistantQuotaException(
      scope: scope,
      resetAt: resetAt is String ? DateTime.tryParse(resetAt) : null,
      requestId: requestId is String && requestId.trim().isNotEmpty
          ? requestId.trim()
          : null,
    );
  }

  /// Pulls the reply out of the webhook body.
  ///
  /// The workflow answers with `output`, `source`, `needs_human`, and `summary`,
  /// but the metadata fields are produced by a language model asked for JSON,
  /// and are the part of the contract most likely to be missing on any given
  /// call. A body carrying only `output` is still a complete answer. The same
  /// tolerance covers an n8n node returning its items unwrapped as a
  /// single-element list, and a field renamed on the workflow side without
  /// anyone telling the app.
  static AssistantReply _readReply(String body) {
    Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      // A plain-text answer is still an answer.
      return AssistantReply(text: body.trim());
    }

    if (decoded is List && decoded.isNotEmpty) {
      decoded = decoded.first;
    }
    if (decoded is String) {
      return AssistantReply(text: decoded.trim());
    }
    if (decoded is! Map) {
      return const AssistantReply(text: '');
    }

    decoded = _unwrap(decoded);

    var text = '';
    for (final key in const ['output', 'answer', 'text', 'message', 'reply']) {
      final value = decoded[key];
      if (value is String && value.trim().isNotEmpty) {
        text = value.trim();
        break;
      }
    }
    return AssistantReply(
      text: text,
      source: decoded['source'] is String
          ? (decoded['source'] as String).trim()
          : '',
      needsHuman: _readFlag(decoded['needs_human']),
      summary: decoded['summary'] is String
          ? (decoded['summary'] as String).trim()
          : '',
    );
  }

  /// Descends past the envelopes n8n puts around a parsed object.
  ///
  /// The Structured Output Parser hands the agent's object back nested under
  /// `output`, so the real body arrives as
  /// `{"output": {"output": ..., "needs_human": ..., "summary": ...}}`. Reading
  /// `output` as the answer text finds an object there and gives up, which the
  /// customer sees as a retry button on a workflow that answered perfectly.
  ///
  /// Unwrapping is bounded and conditional: a wrapper is only stepped through
  /// when its value is itself a map, so the flat shape passes untouched.
  static Map<Object?, Object?> _unwrap(Map<Object?, Object?> body) {
    var current = body;
    for (var depth = 0; depth < 3; depth++) {
      Map<Object?, Object?>? next;
      for (final key in const ['output', 'data', 'json', 'result']) {
        final value = current[key];
        if (value is Map) {
          next = value.cast<Object?, Object?>();
          break;
        }
      }
      if (next == null) {
        return current;
      }
      current = next;
    }
    return current;
  }

  /// Reads a flag a JSON-writing model may have spelled as a string.
  static bool _readFlag(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      return value.trim().toLowerCase() == 'true';
    }
    return false;
  }
}
