import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../services/model/empresa.dart';
import '../services/model/noticia.dart';

/// Option key carrying the record id of the news attached to the popup.
const emergingNewsIdOptionKey = 'NoticiaEmergenteId';

/// Option key carrying the image displayed by the popup.
const emergingNewsImageUrlOptionKey = 'NoticiaEmergenteImagenUrl';

/// Option key carrying the daily presentation limit (integer 1–10).
///
/// Absent or invalid means the legacy rule: each image once per installation.
const emergingNewsTimesPerDayOptionKey = 'NoticiaEmergenteVecesPorDia';

/// Option key carrying the first campaign day (`YYYY-MM-DD`, inclusive).
const emergingNewsStartDateOptionKey = 'NoticiaEmergenteFechaInicio';

/// Option key carrying the last campaign day (`YYYY-MM-DD`, inclusive).
const emergingNewsEndDateOptionKey = 'NoticiaEmergenteFechaFin';

/// Highest daily limit accepted by the Backoffice contract (POPUP-01).
const emergingNewsMaxTimesPerDay = 10;

/// Campaign days follow `America/Santo_Domingo`, which is UTC−4 all year.
const _campaignUtcOffset = Duration(hours: -4);

/// Content selected for an emerging-news popup.
final class EmergingNewsAnnouncement {
  const EmergingNewsAnnouncement({
    required this.imageUrl,
    this.news,
    this.timesPerDay,
    this.campaignDay = '',
  });

  final String imageUrl;
  final Noticia? news;

  /// Daily limit, or `null` for the legacy once-per-image rule.
  final int? timesPerDay;

  /// Campaign day (`YYYY-MM-DD`) in which the announcement was selected.
  final String campaignDay;
}

/// Persistence boundary for popup presentations on this installation.
abstract interface class EmergingNewsSeenStore {
  /// Whether [imageUrl] was ever presented (legacy once-per-image rule).
  Future<bool> contains(String imageUrl);

  Future<void> add(String imageUrl);

  /// Presentations of [campaignKey] recorded on [day].
  Future<int> shownCount(String campaignKey, String day);

  Future<void> recordShown(String campaignKey, String day);
}

/// Stores exact URLs to avoid hash collisions and to survive application restarts.
final class SharedPreferencesEmergingNewsSeenStore
    implements EmergingNewsSeenStore {
  SharedPreferencesEmergingNewsSeenStore(this._preferences);

  static const storageKey = 'emerging_news_seen_image_urls_v1';

  /// Holds only the current campaign day: `{"day": "...", "counts": {...}}`.
  static const dailyStorageKey = 'emerging_news_daily_counts_v1';

  final SharedPreferences _preferences;

  @override
  Future<bool> contains(String imageUrl) async =>
      _preferences.getStringList(storageKey)?.contains(imageUrl) ?? false;

  @override
  Future<void> add(String imageUrl) async {
    final urls = _preferences.getStringList(storageKey)?.toSet() ?? <String>{};
    if (urls.add(imageUrl)) {
      await _preferences.setStringList(
          storageKey, urls.toList(growable: false));
    }
  }

  @override
  Future<int> shownCount(String campaignKey, String day) async =>
      _dailyCounts(day)[campaignKey] ?? 0;

  @override
  Future<void> recordShown(String campaignKey, String day) async {
    // Counts from other days are dropped, so storage never grows past today.
    final counts = _dailyCounts(day);
    counts[campaignKey] = (counts[campaignKey] ?? 0) + 1;
    await _preferences.setString(
      dailyStorageKey,
      jsonEncode({'day': day, 'counts': counts}),
    );
  }

  Map<String, int> _dailyCounts(String day) {
    final raw = _preferences.getString(dailyStorageKey);
    if (raw == null) {
      return {};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['day'] != day) {
        return {};
      }
      final counts = decoded['counts'];
      if (counts is! Map) {
        return {};
      }
      return {
        for (final entry in counts.entries)
          if (entry.key is String && entry.value is int)
            entry.key as String: entry.value as int,
      };
    } on FormatException {
      return {};
    }
  }
}

/// Resolves popup configuration, optional news metadata and eligibility.
final class EmergingNewsCoordinator {
  EmergingNewsCoordinator({
    required Future<Empresa> Function() loadCompany,
    required Future<List<Noticia>> Function() loadNews,
    required EmergingNewsSeenStore store,
    required String courierId,
    DateTime Function() now = DateTime.now,
    this.enforceSeenOnce = true,
  })  : _loadCompany = loadCompany,
        _loadNews = loadNews,
        _store = store,
        _courierId = courierId,
        _now = now;

  final Future<Empresa> Function() _loadCompany;
  final Future<List<Noticia>> Function() _loadNews;
  final EmergingNewsSeenStore _store;
  final String _courierId;
  final DateTime Function() _now;

  /// Whether presentation limits apply (once per image, or N per day).
  ///
  /// Defaults to `true`. Tests or preview tooling can opt out explicitly.
  final bool enforceSeenOnce;

  bool _isChecking = false;

  /// Returns the announcement that may be shown now, when configured.
  Future<EmergingNewsAnnouncement?> findAnnouncement() async {
    if (_isChecking) {
      return null;
    }
    _isChecking = true;
    try {
      final company = await _loadCompany();
      final options = _parseOptions(company.options);
      final imageUrl = _optionText(options, emergingNewsImageUrlOptionKey);
      if (!_isHttpUrl(imageUrl)) {
        return null;
      }

      final today = _campaignDay(_now());
      final start = _optionDay(options, emergingNewsStartDateOptionKey);
      final end = _optionDay(options, emergingNewsEndDateOptionKey);
      // String order matches date order for `YYYY-MM-DD`; start > end never matches.
      if ((start != null && today.compareTo(start) < 0) ||
          (end != null && today.compareTo(end) > 0)) {
        return null;
      }

      final timesPerDay = _optionTimesPerDay(options);
      if (enforceSeenOnce) {
        final exhausted = timesPerDay == null
            ? await _store.contains(imageUrl)
            : await _store.shownCount(_campaignKey(imageUrl), today) >=
                timesPerDay;
        if (exhausted) {
          return null;
        }
      }

      final newsId = _optionText(options, emergingNewsIdOptionKey);
      Noticia? news;
      if (newsId.isNotEmpty) {
        try {
          final availableNews = await _loadNews();
          for (final candidate in availableNews) {
            if (candidate.registroId == newsId) {
              news = candidate;
              break;
            }
          }
        } on Exception {
          // The image campaign is still valid when news metadata is unavailable.
        }
      }
      return EmergingNewsAnnouncement(
        imageUrl: imageUrl,
        news: news,
        timesPerDay: timesPerDay,
        campaignDay: today,
      );
    } finally {
      _isChecking = false;
    }
  }

  /// Records one presentation of [announcement]; call right before opening it.
  ///
  /// The image is also remembered as seen, so switching the campaign back to
  /// the once-per-image rule does not show it again.
  Future<void> markShown(EmergingNewsAnnouncement announcement) async {
    if (!enforceSeenOnce) {
      return;
    }
    if (announcement.timesPerDay != null) {
      await _store.recordShown(
        _campaignKey(announcement.imageUrl),
        announcement.campaignDay,
      );
    }
    await _store.add(announcement.imageUrl);
  }

  /// The art URL is the campaign identity; the courier keeps brands apart.
  String _campaignKey(String imageUrl) => '$_courierId|$imageUrl';
}

/// Campaign day of [instant] in `America/Santo_Domingo`, as `YYYY-MM-DD`.
String _campaignDay(DateTime instant) {
  final local = instant.toUtc().add(_campaignUtcOffset);
  return _formatDay(local.year, local.month, local.day);
}

String _formatDay(int year, int month, int day) =>
    '${year.toString().padLeft(4, '0')}-'
    '${month.toString().padLeft(2, '0')}-'
    '${day.toString().padLeft(2, '0')}';

Map<String, dynamic> _parseOptions(String rawOptions) {
  if (rawOptions.trim().isEmpty) {
    return const {};
  }
  try {
    final decoded = jsonDecode(rawOptions);
    return decoded is Map<String, dynamic> ? decoded : const {};
  } on FormatException {
    return const {};
  }
}

String _optionText(Map<String, dynamic> options, String key) =>
    options[key]?.toString().trim() ?? '';

/// Integer 1–10; any other value counts as absent (legacy rule).
int? _optionTimesPerDay(Map<String, dynamic> options) {
  final value = options[emergingNewsTimesPerDayOptionKey];
  return value is int && value >= 1 && value <= emergingNewsMaxTimesPerDay
      ? value
      : null;
}

final _dayPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

/// Valid `YYYY-MM-DD` calendar day; any other value counts as absent.
String? _optionDay(Map<String, dynamic> options, String key) {
  final value = options[key];
  if (value is! String) {
    return null;
  }
  final match = _dayPattern.firstMatch(value);
  if (match == null) {
    return null;
  }
  final year = int.parse(match[1]!);
  final month = int.parse(match[2]!);
  final day = int.parse(match[3]!);
  final date = DateTime.utc(year, month, day);
  if (date.year != year || date.month != month || date.day != day) {
    return null;
  }
  return value;
}

bool _isHttpUrl(String value) {
  final uri = Uri.tryParse(value);
  return uri != null &&
      uri.host.isNotEmpty &&
      (uri.scheme == 'https' || uri.scheme == 'http');
}
