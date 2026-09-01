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
}

final class _MemorySeenStore implements EmergingNewsSeenStore {
  final Set<String> urls = {};

  @override
  Future<void> add(String imageUrl) async => urls.add(imageUrl);

  @override
  Future<bool> contains(String imageUrl) async => urls.contains(imageUrl);
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
