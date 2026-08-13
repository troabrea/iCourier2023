import 'package:flutter_test/flutter_test.dart';
import 'package:icourier/services/model/noticia.dart';

void main() {
  test('normalizes CMS copy and exposes a safe external destination', () {
    final news = Noticia.fromJson({
      'registroID': ' story-1 ',
      'empresa': 'demo',
      'fecha': '2026-08-12T09:30:00',
      'titulo': ' Nueva ruta ',
      'resumen': '',
      'contenido': '<p>Más rápido &amp; más simple.</p><br>Disponible ahora.',
      'url': 'https://example.com/noticia',
      'deleted': false,
    });

    expect(news.registroId, 'story-1');
    expect(news.titulo, 'Nueva ruta');
    expect(
      news.previewText,
      'Más rápido & más simple.\n\nDisponible ahora.',
    );
    expect(news.externalUri, Uri.https('example.com', '/noticia'));
    expect(news.hasPublishedDate, isTrue);
  });

  test('malformed optional CMS values degrade without losing the feed', () {
    final news = Noticia.fromJson({
      'fecha': 'not-a-date',
      'contenido': null,
      'url': 'javascript:alert(1)',
      'deleted': 'true',
    });

    expect(news.fecha, Noticia.unknownPublishedAt);
    expect(news.hasPublishedDate, isFalse);
    expect(news.titulo, isEmpty);
    expect(news.previewText, isEmpty);
    expect(news.externalUri, isNull);
    expect(news.deleted, isTrue);
    expect(news.heroIdentity, startsWith('local-'));
  });

  test('round-trips the normalized record shape', () {
    final news = Noticia(
      registroId: 'story-2',
      empresa: 'demo',
      fecha: DateTime.utc(2026, 8, 12),
      titulo: 'Aviso',
      resumen: 'Resumen',
      contenido: 'Contenido',
      url: '',
      deleted: false,
    );

    final decoded = Noticia.fromJson(news.toJson());
    expect(decoded.registroId, news.registroId);
    expect(decoded.fecha, news.fecha);
    expect(decoded.previewText, news.resumen);
  });
}
