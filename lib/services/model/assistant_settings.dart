import 'dart:convert';

import 'package:flutter/foundation.dart';

/// The assistant module as the courier's backoffice configured it.
///
/// The record arrives as the JSON string `Empresa.assistantSettings`, written
/// by the admin portal and not by this app, so nothing here may assume the
/// shape is complete. A courier who has not filled the form, a field renamed
/// on the portal side, or a record saved with a trailing comma all have to
/// degrade to [none] rather than break the screens that only want to know
/// whether the module is on.
///
/// The record is public: `/api/empresa/{id}` answers anyone holding the
/// function code, and that code ships inside the app. [apiKey] is therefore a
/// tag the workflow can meter and revoke per courier without a store release,
/// not a secret. Whatever actually protects the workflow has to live on the
/// workflow's side of the call.
@immutable
final class AssistantSettings {
  const AssistantSettings({
    this.name = '',
    this.serviceUrl = '',
    this.apiKey = '',
    this.sessionDailyLimit = unlimited,
    this.companyMonthlyLimit = unlimited,
  });

  /// No record at all, or a record nothing could be read from.
  static const AssistantSettings none = AssistantSettings();

  /// What the portal writes for a limit that is not capped.
  static const int unlimited = -1;

  /// Reads the portal's record, keeping whichever fields survive.
  factory AssistantSettings.parse(String raw) {
    final record = _readObject(raw);
    if (record.isEmpty) {
      return none;
    }
    final service = _readChild(record, 'servicesettings');
    return AssistantSettings(
      name: _readText(record['name']),
      serviceUrl: _readText(service['serviceurl']),
      apiKey: _readText(service['apikey']),
      sessionDailyLimit: _readLimit(service['sessiondailyratelimit']),
      companyMonthlyLimit: _readLimit(service['companymonthlyratelimit']),
    );
  }

  /// What the courier calls the assistant, when they renamed it.
  final String name;

  final String serviceUrl;

  /// Sent as `X-Api-Key` so the workflow can tell the couriers apart.
  final String apiKey;

  /// How many questions one customer may ask per day.
  ///
  /// Both limits are enforced by the workflow, never here: a cap the client
  /// counts is a cap anyone can reset by reinstalling. They are read so the
  /// record round-trips and so a refusal can be explained with the number the
  /// courier actually bought.
  final int sessionDailyLimit;

  /// How many questions the whole company may ask per month.
  final int companyMonthlyLimit;

  /// The workflow this courier's questions go to, when one is configured.
  ///
  /// Anything that is not plain http(s) is dropped: the value is hand-typed in
  /// a portal field, and sending a question to a `javascript:` or `file:` URI
  /// is never what the courier meant.
  Uri? get endpoint {
    final uri = Uri.tryParse(serviceUrl.trim());
    if (uri == null || !uri.isAbsolute) {
      return null;
    }
    return uri.scheme == 'https' || uri.scheme == 'http' ? uri : null;
  }

  /// Reads the body as an object with lower-cased keys.
  ///
  /// The portal writes `PascalCase`, but the field is edited by hand and has
  /// already been serialized by more than one backend, so matching on case
  /// would turn a harmless `serviceUrl` into a courier with no assistant.
  static Map<String, Object?> _readObject(String raw) {
    if (raw.trim().isEmpty) {
      return const {};
    }
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return const {};
    }
    return decoded is Map ? _lowerKeys(decoded) : const {};
  }

  static Map<String, Object?> _readChild(
      Map<String, Object?> record, String key) {
    final value = record[key];
    return value is Map ? _lowerKeys(value) : const {};
  }

  static Map<String, Object?> _lowerKeys(Map<Object?, Object?> source) => {
        for (final entry in source.entries)
          entry.key.toString().toLowerCase(): entry.value,
      };

  static String _readText(Object? value) => value is String ? value.trim() : '';

  /// Reads a limit a portal field may have saved as text.
  static int _readLimit(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim()) ?? unlimited;
    }
    return unlimited;
  }
}
