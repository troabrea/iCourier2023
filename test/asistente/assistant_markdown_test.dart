import 'package:flutter_test/flutter_test.dart';
import 'package:icourier/asistente/assistant_markdown.dart';

/// A verbatim shape the live workflow returns for a branch question.
const _branchAnswer = '''
¡Claro, Temístocles! Aquí tienes la información:

**Santo Domingo:**

*   **Paseo 27:** Zona Franca, KM 22. Horario: L-V 9:00am a 7:00pm.
*   **La Julia:** Av. Winston Churchill, No 51.

Si necesitas otra cosa, dime.
''';

String _plain(List<AssistantSpan> spans) =>
    spans.map((span) => span.text).join();

void main() {
  group('blocks', () {
    test('reads the shape the workflow actually returns', () {
      final blocks = parseAssistantMarkdown(_branchAnswer);

      expect(
        blocks.map((block) => block.kind).toList(),
        [
          AssistantBlockKind.paragraph,
          AssistantBlockKind.paragraph,
          AssistantBlockKind.listItem,
          AssistantBlockKind.listItem,
          AssistantBlockKind.paragraph,
        ],
      );
      expect(_plain(blocks[1].spans), 'Santo Domingo:');
      expect(blocks[1].spans.single.bold, isTrue);
      expect(
        _plain(blocks[2].spans),
        'Paseo 27: Zona Franca, KM 22. Horario: L-V 9:00am a 7:00pm.',
      );
      expect(blocks[2].marker, isNull);
    });

    test('joins the lines of one paragraph and splits on the blank line', () {
      final blocks = parseAssistantMarkdown('una\nlinea\n\notro parrafo');

      expect(blocks, hasLength(2));
      expect(_plain(blocks.first.spans), 'una linea');
      expect(_plain(blocks.last.spans), 'otro parrafo');
    });

    test('numbers an ordered list and keeps its marker', () {
      final blocks = parseAssistantMarkdown('1. uno\n2) dos');

      expect(blocks.map((block) => block.marker).toList(), ['1.', '2.']);
      expect(blocks.every((b) => b.kind == AssistantBlockKind.listItem), isTrue);
    });

    test('recognises headings and rules', () {
      final blocks = parseAssistantMarkdown('## Sucursales\n\n---\n\ntexto');

      expect(blocks.first.kind, AssistantBlockKind.heading);
      expect(_plain(blocks.first.spans), 'Sucursales');
      expect(blocks[1].kind, AssistantBlockKind.rule);
    });
  });

  group('emphasis', () {
    test('keeps bold, italic and code apart', () {
      final spans = parseAssistantSpans('a **b** c *d* e `f`');

      expect(spans.where((span) => span.bold).map((s) => s.text), ['b']);
      expect(spans.where((span) => span.italic).map((s) => s.text), ['d']);
      expect(spans.where((span) => span.code).map((s) => s.text), ['f']);
      expect(_plain(spans), 'a b c d e f');
    });

    test('a bold run is never mistaken for two italics', () {
      final spans = parseAssistantSpans('**Paseo 27:** Zona Franca');

      expect(spans.first.text, 'Paseo 27:');
      expect(spans.first.bold, isTrue);
      expect(spans.first.italic, isFalse);
    });

    test('an account code keeps its underscores', () {
      expect(_plain(parseAssistantSpans('BM_096791_A')), 'BM_096791_A');
    });

    test('a link carries its target', () {
      final spans = parseAssistantSpans('Ver [la web](https://example.test).');

      expect(spans[1].text, 'la web');
      expect(spans[1].link, 'https://example.test');
      expect(_plain(spans), 'Ver la web.');
    });

    test('plain text comes back whole', () {
      expect(_plain(parseAssistantSpans('sin formato')), 'sin formato');
    });
  });

  group('links the app can open', () {
    test('accepts the schemes the screen actually launches', () {
      for (final link in const [
        'https://example.test',
        'http://example.test',
        'mailto:soporte@example.test',
        'tel:+18091234567',
      ]) {
        expect(isSupportedAssistantLink(link), isTrue, reason: link);
      }
    });

    test('refuses anything that would render as a control doing nothing', () {
      for (final link in const [
        'javascript:alert(1)',
        'ftp://example.test',
        'sin-esquema',
        null,
      ]) {
        expect(isSupportedAssistantLink(link), isFalse, reason: '$link');
      }
    });
  });

  test('an empty answer produces no blocks rather than throwing', () {
    expect(parseAssistantMarkdown(''), isEmpty);
  });
}
