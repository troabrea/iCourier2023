import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../services/model/empresa.dart';
import '../services/model/noticia.dart';

/// Option key carrying the record id of the news attached to the popup.
const emergingNewsIdOptionKey = 'NoticiaEmergenteId';

/// Option key carrying the image displayed by the popup.
const emergingNewsImageUrlOptionKey = 'NoticiaEmergenteImagenUrl';

/// Content selected for a one-time emerging-news popup.
final class EmergingNewsAnnouncement {
  const EmergingNewsAnnouncement({
    required this.imageUrl,
    this.news,
  });

  final String imageUrl;
  final Noticia? news;
}

/// Persistence boundary for images already presented on this installation.
abstract interface class EmergingNewsSeenStore {
  Future<bool> contains(String imageUrl);

  Future<void> add(String imageUrl);
}

/// Stores exact URLs to avoid hash collisions and to survive application restarts.
final class SharedPreferencesEmergingNewsSeenStore
    implements EmergingNewsSeenStore {
  SharedPreferencesEmergingNewsSeenStore(this._preferences);

  static const storageKey = 'emerging_news_seen_image_urls_v1';

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
}

/// Resolves popup configuration, optional news metadata and one-time eligibility.
final class EmergingNewsCoordinator {
  EmergingNewsCoordinator({
    required Future<Empresa> Function() loadCompany,
    required Future<List<Noticia>> Function() loadNews,
    required EmergingNewsSeenStore store,
    this.enforceSeenOnce = true,
  })  : _loadCompany = loadCompany,
        _loadNews = loadNews,
        _store = store;

  final Future<Empresa> Function() _loadCompany;
  final Future<List<Noticia>> Function() _loadNews;
  final EmergingNewsSeenStore _store;

  /// Whether each image is presented only once on this installation.
  ///
  /// Defaults to `true`. Tests or preview tooling can opt out explicitly.
  final bool enforceSeenOnce;

  bool _isChecking = false;

  /// Returns the announcement that has not yet been shown, when configured.
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
      if (enforceSeenOnce && await _store.contains(imageUrl)) {
        return null;
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
      return EmergingNewsAnnouncement(imageUrl: imageUrl, news: news);
    } finally {
      _isChecking = false;
    }
  }

  /// Remembers [announcement] when one-time presentation is enabled.
  Future<void> markShown(EmergingNewsAnnouncement announcement) {
    if (!enforceSeenOnce) {
      return Future<void>.value();
    }
    return _store.add(announcement.imageUrl);
  }
}

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

bool _isHttpUrl(String value) {
  final uri = Uri.tryParse(value);
  return uri != null &&
      uri.host.isNotEmpty &&
      (uri.scheme == 'https' || uri.scheme == 'http');
}
