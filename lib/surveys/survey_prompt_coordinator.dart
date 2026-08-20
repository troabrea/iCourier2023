import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../services/model/empresa.dart';

/// A currently active survey published by the courier company.
final class SurveyInvitation {
  const SurveyInvitation({required this.uri, required this.activeThrough});

  final Uri uri;
  final DateTime activeThrough;

  /// Resolves the company's survey without applying local prompt history.
  ///
  /// This is intentionally independent from answer and snooze state so the
  /// notification center can keep a manual recovery path available.
  static SurveyInvitation? activeFor(Empresa company, DateTime at) {
    final uri = _validSurveyUri(company.encuestaUrl);
    if (uri == null) {
      return null;
    }

    final activeThrough = _inclusiveActiveThrough(
      company.encuestaActiveUntil,
    );
    if (at.isAfter(activeThrough)) {
      return null;
    }
    return SurveyInvitation(uri: uri, activeThrough: activeThrough);
  }

  static Uri? _validSurveyUri(String rawUrl) {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      return null;
    }
    return uri;
  }

  static DateTime _inclusiveActiveThrough(DateTime configured) {
    final isDateOnly = configured.hour == 0 &&
        configured.minute == 0 &&
        configured.second == 0 &&
        configured.millisecond == 0 &&
        configured.microsecond == 0;
    if (!isDateOnly) {
      return configured;
    }
    return configured
        .add(const Duration(days: 1))
        .subtract(const Duration(microseconds: 1));
  }
}

/// A temporary suppression tied to one survey URL.
final class SurveySnooze {
  const SurveySnooze({required this.url, required this.until});

  final String url;
  final DateTime until;
}

/// Persists whether a survey was handled or postponed on this device.
abstract interface class SurveyPromptStore {
  Future<String?> readAnsweredUrl();

  Future<SurveySnooze?> readSnooze();

  Future<void> markAnswered(String url);

  Future<void> snooze(String url, DateTime until);
}

/// Stores survey prompt state alongside the rest of the application settings.
final class SharedPreferencesSurveyPromptStore implements SurveyPromptStore {
  SharedPreferencesSurveyPromptStore(this._preferences);

  static const answeredUrlKey = 'survey_prompt.answered_url';
  static const snoozedUrlKey = 'survey_prompt.snoozed_url';
  static const snoozedUntilKey = 'survey_prompt.snoozed_until';
  static const _legacyAnsweredUrlKey = 'lastEncuestaUrl';

  final SharedPreferences _preferences;

  @override
  Future<String?> readAnsweredUrl() async {
    final stored = _preferences.getString(answeredUrlKey);
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }

    final legacy = _readLegacyAnsweredUrl();
    if (legacy == null || legacy.isEmpty) {
      return null;
    }
    await _preferences.setString(answeredUrlKey, legacy);
    return legacy;
  }

  @override
  Future<SurveySnooze?> readSnooze() async {
    final url = _preferences.getString(snoozedUrlKey);
    final timestamp = _preferences.getInt(snoozedUntilKey);
    if (url == null || url.isEmpty || timestamp == null) {
      return null;
    }
    return SurveySnooze(
      url: url,
      until: DateTime.fromMillisecondsSinceEpoch(timestamp),
    );
  }

  @override
  Future<void> markAnswered(String url) async {
    await _preferences.setString(answeredUrlKey, url);
    await _preferences.remove(snoozedUrlKey);
    await _preferences.remove(snoozedUntilKey);
  }

  @override
  Future<void> snooze(String url, DateTime until) async {
    await _preferences.setString(snoozedUrlKey, url);
    await _preferences.setInt(
      snoozedUntilKey,
      until.millisecondsSinceEpoch,
    );
  }

  String? _readLegacyAnsweredUrl() {
    final descriptor = _preferences.getString(_legacyAnsweredUrlKey);
    if (descriptor == null || descriptor.isEmpty) {
      return null;
    }
    if (descriptor.startsWith('http://') || descriptor.startsWith('https://')) {
      return descriptor;
    }
    try {
      final decoded = jsonDecode(descriptor);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final contentKey = decoded['content'];
      return contentKey is String ? _preferences.getString(contentKey) : null;
    } on FormatException {
      return null;
    }
  }
}

/// Resolves survey eligibility and owns its answer/snooze policy.
final class SurveyPromptCoordinator {
  SurveyPromptCoordinator({
    required Future<Empresa> Function() loadCompany,
    required SurveyPromptStore store,
    DateTime Function()? clock,
    this.snoozeDuration = const Duration(days: 3),
  })  : _loadCompany = loadCompany,
        _store = store,
        _clock = clock ?? DateTime.now;

  final Future<Empresa> Function() _loadCompany;
  final SurveyPromptStore _store;
  final DateTime Function() _clock;
  final Duration snoozeDuration;
  bool _isChecking = false;

  /// Returns the survey that should be offered now, if there is one.
  Future<SurveyInvitation?> findInvitation() async {
    if (_isChecking) {
      return null;
    }
    _isChecking = true;
    try {
      final company = await _loadCompany();
      final now = _clock();
      final invitation = SurveyInvitation.activeFor(company, now);
      if (invitation == null) {
        return null;
      }

      final url = invitation.uri.toString();
      if (await _store.readAnsweredUrl() == url) {
        return null;
      }

      final snooze = await _store.readSnooze();
      if (snooze?.url == url && now.isBefore(snooze!.until)) {
        return null;
      }
      return invitation;
    } finally {
      _isChecking = false;
    }
  }

  /// Suppresses [invitation] until the standard reminder interval elapses.
  Future<void> postpone(SurveyInvitation invitation) => _store.snooze(
        invitation.uri.toString(),
        _clock().add(snoozeDuration),
      );

  /// Prevents [invitation] from being offered again on this device.
  Future<void> markAnswered(SurveyInvitation invitation) =>
      _store.markAnswered(invitation.uri.toString());
}
