import 'package:flutter_test/flutter_test.dart';
import 'package:icourier/asistente/assistant_shortcuts.dart';
import 'package:icourier/navigation/app_routes.dart';

const _everything = <String>{
  AppRoutes.receptions,
  AppRoutes.history,
  AppRoutes.branches,
  AppRoutes.services,
  AppRoutes.tracking,
  AppRoutes.calculator,
  AppRoutes.invoices,
  AppRoutes.accountStatement,
  AppRoutes.prealert,
  AppRoutes.faq,
};

List<String> _routes({
  required String question,
  String answer = '',
  String source = '',
  Set<String> available = _everything,
}) =>
    AssistantShortcuts.resolve(
      question: question,
      answer: answer,
      source: source,
      available: available,
    ).map((shortcut) => shortcut.route).toList();

void main() {
  group('structured source', () {
    const expectedRoutes = {
      'get_paquetes': AppRoutes.receptions,
      'get_historico': AppRoutes.history,
      'calcula_envio': AppRoutes.calculator,
      'get_sucursales': AppRoutes.branches,
      'get_servicios': AppRoutes.services,
      'get_preguntas': AppRoutes.faq,
      'crear_prealerta': AppRoutes.prealert,
      'crear_postalerta': AppRoutes.receptions,
    };

    for (final entry in expectedRoutes.entries) {
      test('${entry.key} maps directly to ${entry.value}', () {
        expect(
          _routes(question: 'texto sin relación', source: entry.key),
          [entry.value],
        );
      });
    }

    test('takes precedence over conflicting prose', () {
      expect(
        _routes(
          question: '¿Tengo paquetes activos?',
          answer: 'Tienes un paquete disponible.',
          source: 'get_historico',
        ),
        [AppRoutes.history],
      );
    });

    test('does not infer a shortcut for a conversational answer', () {
      expect(
        _routes(
          question: '¿Tengo paquetes?',
          answer: 'Hablemos de sus paquetes.',
          source: 'conversacion',
        ),
        isEmpty,
      );
    });

    test('does not infer a shortcut for an unknown non-empty source', () {
      expect(
        _routes(
          question: '¿Tengo paquetes?',
          source: 'herramienta_nueva',
        ),
        isEmpty,
      );
    });

    test('does not offer a mapped module the brand disabled', () {
      expect(
        _routes(
          question: 'Quiero hacer una prealerta',
          source: 'crear_prealerta',
          available: _everything.difference({AppRoutes.prealert}),
        ),
        isEmpty,
      );
    });

    test('an empty source falls back to the prose rules', () {
      expect(
        _routes(question: '¿Tengo paquetes?', source: '   '),
        [AppRoutes.receptions],
      );
    });
  });

  test('offers the packages screen when the answer is about packages', () {
    expect(
      _routes(
        question: 'Tengo paquetes',
        answer: 'Tienes 2 paquetes disponibles para retiro.',
      ).first,
      AppRoutes.receptions,
    );
  });

  test('matches a question typed without accents', () {
    expect(
      _routes(question: 'cual es la direccion de mi sucursal'),
      contains(AppRoutes.branches),
    );
  });

  test('never offers more than two destinations', () {
    final routes = _routes(
      question: 'paquetes, sucursales, servicios, factura y calculadora',
      answer: 'prealerta rastreo estado de cuenta horario libras',
    );

    expect(routes, hasLength(AssistantShortcuts.maxShortcuts));
  });

  test('ranks the intent the exchange leaned on hardest first', () {
    expect(
      _routes(
        question: '¿Cuánto cuesta traer 5 libras?',
        answer: 'El costo por libra depende del servicio. Usa la calculadora.',
      ).first,
      AppRoutes.calculator,
    );
  });

  test('never offers a module this brand did not enable', () {
    expect(
      _routes(
        question: 'Quiero hacer una prealerta',
        available: _everything.difference({AppRoutes.prealert}),
      ),
      isNot(contains(AppRoutes.prealert)),
    );
  });

  test('offers nothing for small talk', () {
    expect(_routes(question: 'Gracias, muy amable'), isEmpty);
  });

  group('live packages versus the history', () {
    test('a plain package question keeps the current reception list', () {
      final routes = _routes(
        question: '¿Tengo paquetes?',
        answer: 'Tienes 2 paquetes disponibles para retiro en La Julia.',
      );

      expect(routes.first, AppRoutes.receptions);
      expect(routes, isNot(contains(AppRoutes.history)));
    });

    test('an explicit past period sends the customer to the date search', () {
      final routes = _routes(
        question: '¿Qué paquetes me llegaron el mes pasado?',
        answer: 'En el mes pasado recibiste 3 paquetes.',
      );

      expect(routes, contains(AppRoutes.history));
      expect(routes, isNot(contains(AppRoutes.receptions)));
      expect(routes, isNot(contains(AppRoutes.tracking)));
    });

    test('the answer naming the historical search is enough on its own', () {
      final routes = _routes(
        question: '¿Y mis paquetes de antes?',
        answer: 'Esos ya no aparecen aquí. Usa la consulta histórica.',
      );

      expect(routes, contains(AppRoutes.history));
      expect(routes, isNot(contains(AppRoutes.receptions)));
    });

    test('a mixed answer offers both, because the question was about both', () {
      final routes = _routes(
        question: '¿Cómo van mis paquetes?',
        answer: 'Tienes 2 paquetes disponibles y 1 fue entregado ayer.',
      );

      expect(routes, contains(AppRoutes.receptions));
      expect(routes, contains(AppRoutes.history));
    });

    test('a question about branches never reaches the history', () {
      expect(
        _routes(
          question: '¿Cuál es el horario de mi sucursal?',
          answer: 'La Julia abre de 9:00am a 7:00pm.',
        ),
        isNot(contains(AppRoutes.history)),
      );
    });

    test('matching without accents works for the history too', () {
      expect(
        _routes(question: 'quiero ver mis paquetes historicos'),
        contains(AppRoutes.history),
      );
    });
  });

  group('answers captured from the live workflow', () {
    // Verbatim, so a change in how the workflow writes shows up here first.
    const historyAnswer = '''
Temístocles, durante el último mes, has recibido los siguientes paquetes:

*   **WR010035050937**: Ropa de Shein, con un peso de 1.65 libras. El monto a pagar es \$417,04.
*   **WR010034995958**: Zapatos de Amazon, con un peso de 1.80 libras. El monto a pagar es \$453,48.
*   **WR010034979773**: Un libro de Thriftbooks, con un peso de 1.35 libras. El monto a pagar es \$344,14.
''';

    test('a month of received packages leads with the date search', () {
      final routes = _routes(
        question: '¿Qué paquetes me llegaron el mes pasado?',
        answer: historyAnswer,
      );

      expect(routes.first, AppRoutes.history);
      expect(routes, isNot(contains(AppRoutes.receptions)));
      // Every line names a weight; that is cargo, not a calculator question.
      expect(routes, isNot(contains(AppRoutes.calculator)));
    });

    test('the workflow saying "último mes" is decisive on its own', () {
      final routes =
          _routes(question: '¿Y lo de antes?', answer: historyAnswer);

      expect(routes.first, AppRoutes.history);
    });

    test('having nothing active still points at the current list', () {
      final routes = _routes(
        question: '¿Tengo paquetes?',
        answer:
            'No, Temístocles. Según mi información, no tienes ningún paquete '
            'activo en este momento.',
      );

      expect(routes.first, AppRoutes.receptions);
      expect(routes, isNot(contains(AppRoutes.history)));
    });
  });

  test('a shortcut always carries a translation key, never a literal', () {
    final shortcuts = AssistantShortcuts.resolve(
      question: 'sucursales',
      answer: '',
      available: _everything,
    );

    expect(shortcuts.single.labelKey, 'asistente_ir_sucursales');
  });
}
