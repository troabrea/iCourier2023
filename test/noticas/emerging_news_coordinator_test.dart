import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:icourier/noticas/emerging_news_coordinator.dart';
import 'package:icourier/services/model/empresa.dart';
import 'package:icourier/services/model/noticia.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('selects configured image and matching news', () async {
    final store = _MemorySeenStore();
    final news = _news('news-42');
    final coordinator = EmergingNewsCoordinator(
      loadCompany: () async => _company(
        imageUrl: 'https://cdn.example.com/alert.jpg',
        newsId: 'news-42',
      ),
      loadNews: () async => [news],
      store: store,
      courierId: 'courier',
    );

    final announcement = await coordinator.findAnnouncement();

    expect(announcement?.imageUrl, 'https://cdn.example.com/alert.jpg');
    expect(announcement?.news, same(news));
  });

  test('keeps the image when the configured news is unavailable', () async {
    final coordinator = EmergingNewsCoordinator(
      loadCompany: () async => _company(
        imageUrl: 'https://cdn.example.com/alert.jpg',
        newsId: 'missing',
      ),
      loadNews: () async => [_news('another-news')],
      store: _MemorySeenStore(),
      courierId: 'courier',
    );

    final announcement = await coordinator.findAnnouncement();

    expect(announcement, isNotNull);
    expect(announcement?.news, isNull);
  });

  test('returns each image only once by default', () async {
    const imageUrl = 'https://cdn.example.com/alert.jpg';
    final store = _MemorySeenStore();
    final coordinator = EmergingNewsCoordinator(
      loadCompany: () async => _company(imageUrl: imageUrl),
      loadNews: () async => [],
      store: store,
      courierId: 'courier',
    );
    final first = await coordinator.findAnnouncement();
    await coordinator.markShown(first!);

    final second = await coordinator.findAnnouncement();

    expect(store.urls, {imageUrl});
    expect(second, isNull);
  });

  test('can disable one-time control explicitly', () async {
    const imageUrl = 'https://cdn.example.com/alert.jpg';
    final store = _MemorySeenStore();
    final coordinator = EmergingNewsCoordinator(
      loadCompany: () async => _company(imageUrl: imageUrl),
      loadNews: () async => [],
      store: store,
      courierId: 'courier',
      enforceSeenOnce: false,
    );
    final first = await coordinator.findAnnouncement();
    await coordinator.markShown(first!);

    final second = await coordinator.findAnnouncement();

    expect(store.urls, isEmpty);
    expect(second, isNotNull);
  });

  test('ignores empty and malformed image URLs', () async {
    for (final imageUrl in ['', 'not a web url']) {
      final coordinator = EmergingNewsCoordinator(
        loadCompany: () async => _company(imageUrl: imageUrl),
        loadNews: () async => [],
        store: _MemorySeenStore(),
        courierId: 'courier',
      );

      expect(await coordinator.findAnnouncement(), isNull);
    }
  });

  test('SharedPreferences store remembers every previously shown URL',
      () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final firstStore = SharedPreferencesEmergingNewsSeenStore(preferences);
    await firstStore.add('https://cdn.example.com/first.jpg');
    await firstStore.add('https://cdn.example.com/second.jpg');

    final restoredStore = SharedPreferencesEmergingNewsSeenStore(preferences);

    expect(
      await restoredStore.contains('https://cdn.example.com/first.jpg'),
      isTrue,
    );
    expect(
      await restoredStore.contains('https://cdn.example.com/second.jpg'),
      isTrue,
    );
  });
  group('daily frequency', () {
    test('shows at most N times per campaign day', () async {
      final campaign =
          _Campaign(options: {emergingNewsTimesPerDayOptionKey: 3});
      final store = _MemorySeenStore();

      expect(await _showRepeatedly(campaign.coordinator(store)), 3);
      // A restart builds a new coordinator over the same persisted store.
      expect(await _showOnce(campaign.coordinator(store)), isFalse);
    });

    test('resets at midnight in Santo Domingo, not after 24 hours', () async {
      // 03:59 UTC on Nov 8 is still 23:59 on Nov 7 in Santo Domingo.
      final campaign = _Campaign(
        options: {emergingNewsTimesPerDayOptionKey: 1},
        now: DateTime.utc(2026, 11, 8, 3, 59),
      );
      final store = _MemorySeenStore();
      final coordinator = campaign.coordinator(store);

      expect(await _showOnce(coordinator), isTrue);
      expect(await _showOnce(coordinator), isFalse);

      campaign.now = DateTime.utc(2026, 11, 8, 4);
      expect(await _showOnce(coordinator), isTrue);
      expect(await _showOnce(coordinator), isFalse);
    });

    test('uses the campaign day even when the device clock is local', () async {
      // 2026-11-07 23:30 in Santo Domingo, read in the device's own zone.
      final deviceInstant = DateTime.utc(2026, 11, 8, 3, 30).toLocal();
      final campaign = _Campaign(
        options: {
          emergingNewsTimesPerDayOptionKey: 1,
          emergingNewsEndDateOptionKey: '2026-11-07',
        },
        now: deviceInstant,
      );

      expect(await _showOnce(campaign.coordinator(_MemorySeenStore())), isTrue);
    });

    test('changing N keeps today consumption', () async {
      final campaign =
          _Campaign(options: {emergingNewsTimesPerDayOptionKey: 3});
      final store = _MemorySeenStore();
      final coordinator = campaign.coordinator(store);
      await _showOnce(coordinator);
      await _showOnce(coordinator);

      campaign.options = {emergingNewsTimesPerDayOptionKey: 1};
      expect(await _showOnce(coordinator), isFalse);

      campaign.options = {emergingNewsTimesPerDayOptionKey: 3};
      expect(await _showRepeatedly(coordinator), 1);
    });

    test('new art is a new campaign with its own quota', () async {
      final campaign =
          _Campaign(options: {emergingNewsTimesPerDayOptionKey: 1});
      final store = _MemorySeenStore();
      final coordinator = campaign.coordinator(store);
      expect(await _showOnce(coordinator), isTrue);
      expect(await _showOnce(coordinator), isFalse);

      campaign.imageUrl = 'https://cdn.example.com/other.jpg';
      expect(await _showOnce(coordinator), isTrue);
    });

    test('couriers do not share counters', () async {
      final campaign =
          _Campaign(options: {emergingNewsTimesPerDayOptionKey: 1});
      final store = _MemorySeenStore();

      expect(
          await _showOnce(campaign.coordinator(store, courierId: 'a')), isTrue);
      expect(
          await _showOnce(campaign.coordinator(store, courierId: 'b')), isTrue);
      expect(await _showOnce(campaign.coordinator(store, courierId: 'a')),
          isFalse);
    });

    test('art already seen under the legacy rule starts a fresh daily quota',
        () async {
      final campaign =
          _Campaign(options: {emergingNewsTimesPerDayOptionKey: 2});
      final store = _MemorySeenStore()..urls.add(campaign.imageUrl);

      expect(await _showRepeatedly(campaign.coordinator(store)), 2);
    });

    test('dropping N back to the legacy rule does not show seen art again',
        () async {
      final campaign =
          _Campaign(options: {emergingNewsTimesPerDayOptionKey: 2});
      final store = _MemorySeenStore();
      final coordinator = campaign.coordinator(store);
      await _showOnce(coordinator);

      campaign.options = const {};
      expect(await _showOnce(coordinator), isFalse);
    });

    test('invalid limits fall back to once per image, never unlimited',
        () async {
      for (final value in <Object?>['3', 3.5, 0, -1, 11, null, true]) {
        final campaign =
            _Campaign(options: {emergingNewsTimesPerDayOptionKey: value});
        final store = _MemorySeenStore();
        final coordinator = campaign.coordinator(store);

        expect(await _showRepeatedly(coordinator), 1, reason: '$value');
        campaign.now = campaign.now.add(const Duration(days: 1));
        expect(await _showOnce(coordinator), isFalse, reason: '$value');
      }
    });

    test('accepts the maximum limit of 10', () async {
      final campaign = _Campaign(options: {
        emergingNewsTimesPerDayOptionKey: emergingNewsMaxTimesPerDay,
      });

      expect(
        await _showRepeatedly(campaign.coordinator(_MemorySeenStore()),
            attempts: 15),
        10,
      );
    });
  });

  group('campaign dates', () {
    Future<bool> availableOn(DateTime now, Map<String, Object?> options) =>
        _showOnce(_Campaign(
          options: {emergingNewsTimesPerDayOptionKey: 1, ...options},
          now: now,
        ).coordinator(_MemorySeenStore()));

    const window = {
      emergingNewsStartDateOptionKey: '2026-11-15',
      emergingNewsEndDateOptionKey: '2026-11-30',
    };

    test('start and end days are inclusive in Santo Domingo', () async {
      // 2026-11-15 00:00 and 2026-11-30 23:59 in Santo Domingo.
      expect(await availableOn(DateTime.utc(2026, 11, 15, 4), window), isTrue);
      expect(
          await availableOn(DateTime.utc(2026, 12, 1, 3, 59), window), isTrue);
    });

    test('hides the popup before the start and after the end', () async {
      expect(await availableOn(DateTime.utc(2026, 11, 15, 3, 59), window),
          isFalse);
      expect(await availableOn(DateTime.utc(2026, 12, 1, 4), window), isFalse);
    });

    test('dates also apply to the once-per-image rule', () async {
      final campaign = _Campaign(
        options: {emergingNewsEndDateOptionKey: '2026-11-01'},
      );

      expect(
          await _showOnce(campaign.coordinator(_MemorySeenStore())), isFalse);
    });

    test('start after end never shows', () async {
      expect(
        await availableOn(DateTime.utc(2026, 11, 20, 15), {
          emergingNewsStartDateOptionKey: '2026-11-30',
          emergingNewsEndDateOptionKey: '2026-11-15',
        }),
        isFalse,
      );
    });

    test('malformed dates count as absent', () async {
      for (final value in <Object?>[
        '2026-02-30',
        '15/11/2026',
        '2026-11-15T00:00:00',
        20261115,
        '',
      ]) {
        expect(
          await availableOn(DateTime.utc(2026, 11, 7, 15), {
            emergingNewsStartDateOptionKey: value,
            emergingNewsEndDateOptionKey: value,
          }),
          isTrue,
          reason: '$value',
        );
      }
    });
  });

  group('SharedPreferences daily store', () {
    test('persists counts per day and keeps only the current day', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesEmergingNewsSeenStore.storageKey: ['legacy-url'],
        'unrelated': 'kept',
      });
      final preferences = await SharedPreferences.getInstance();
      final store = SharedPreferencesEmergingNewsSeenStore(preferences);
      await store.recordShown('a|url', '2026-11-07');
      await store.recordShown('a|url', '2026-11-07');
      await store.recordShown('b|url', '2026-11-07');

      final restored = SharedPreferencesEmergingNewsSeenStore(preferences);
      expect(await restored.shownCount('a|url', '2026-11-07'), 2);
      expect(await restored.shownCount('b|url', '2026-11-07'), 1);
      expect(await restored.shownCount('a|url', '2026-11-08'), 0);

      await restored.recordShown('a|url', '2026-11-08');
      final stored = jsonDecode(preferences
          .getString(SharedPreferencesEmergingNewsSeenStore.dailyStorageKey)!);
      expect(stored, {
        'day': '2026-11-08',
        'counts': {'a|url': 1},
      });
      expect(await restored.contains('legacy-url'), isTrue);
      expect(preferences.getString('unrelated'), 'kept');
    });

    test('corrupt daily data reads as zero and is replaced on write', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesEmergingNewsSeenStore.dailyStorageKey: '{not json',
      });
      final preferences = await SharedPreferences.getInstance();
      final store = SharedPreferencesEmergingNewsSeenStore(preferences);

      expect(await store.shownCount('a|url', '2026-11-07'), 0);
      await store.recordShown('a|url', '2026-11-07');
      expect(await store.shownCount('a|url', '2026-11-07'), 1);
    });
  });
}

final class _MemorySeenStore implements EmergingNewsSeenStore {
  final Set<String> urls = {};
  final Map<String, int> dailyCounts = {};

  @override
  Future<void> add(String imageUrl) async => urls.add(imageUrl);

  @override
  Future<bool> contains(String imageUrl) async => urls.contains(imageUrl);

  @override
  Future<int> shownCount(String campaignKey, String day) async =>
      dailyCounts['$day $campaignKey'] ?? 0;

  @override
  Future<void> recordShown(String campaignKey, String day) async => dailyCounts
      .update('$day $campaignKey', (count) => count + 1, ifAbsent: () => 1);
}

/// Mutable clock and options, so one test can move through days and edits.
final class _Campaign {
  _Campaign({
    this.options = const {},
    DateTime? now,
  }) : now = now ?? DateTime.utc(2026, 11, 7, 15);

  String imageUrl = 'https://cdn.example.com/daily.jpg';
  Map<String, Object?> options;
  DateTime now;

  EmergingNewsCoordinator coordinator(
    EmergingNewsSeenStore store, {
    String courierId = 'courier',
  }) =>
      EmergingNewsCoordinator(
        loadCompany: () async => Empresa.empty()
          ..options = jsonEncode({
            emergingNewsImageUrlOptionKey: imageUrl,
            ...options,
          }),
        loadNews: () async => [],
        store: store,
        courierId: courierId,
        now: () => now,
      );
}

/// Finds and records one presentation; returns whether it was available.
Future<bool> _showOnce(EmergingNewsCoordinator coordinator) async {
  final announcement = await coordinator.findAnnouncement();
  if (announcement == null) {
    return false;
  }
  await coordinator.markShown(announcement);
  return true;
}

Future<int> _showRepeatedly(EmergingNewsCoordinator coordinator,
    {int attempts = 12}) async {
  var shown = 0;
  for (var i = 0; i < attempts; i++) {
    if (await _showOnce(coordinator)) {
      shown++;
    }
  }
  return shown;
}

Empresa _company({required String imageUrl, String newsId = ''}) {
  final company = Empresa.empty();
  company.options = jsonEncode({
    emergingNewsImageUrlOptionKey: imageUrl,
    emergingNewsIdOptionKey: newsId,
  });
  return company;
}

Noticia _news(String id) => Noticia(
      registroId: id,
      empresa: 'company',
      fecha: DateTime(2026, 8, 29),
      titulo: 'Operación especial',
      resumen: 'Conoce los detalles de nuestro horario especial.',
      contenido: 'Contenido completo.',
      url: '',
      deleted: false,
    );
