import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:icourier/services/assistant_service.dart';
import 'package:icourier/services/model/asistente_model.dart';

const _identity = AssistantIdentity(
  empresaId: 'ebb66ab7-db15-4267-9ef4-92abcb5273eb',
  sessionId: '0x0200000027',
  firstName: 'Temístocles',
  lastName: 'Roa Pérez',
  userAccount: 'BM-096791',
  sucursalId: 'DO-BVT',
);

AssistantService _service(MockClient client, {AssistantIdentity? identity}) =>
    AssistantService(
      client: client,
      endpoint: Uri.parse('https://example.test/assistant'),
      identity: () async => identity ?? _identity,
    );

void main() {
  test('sends every field the workflow expects, as UTF-8 JSON', () async {
    Request? sent;
    final service = _service(
      MockClient((request) async {
        sent = request;
        return Response(
          jsonEncode({'output': 'Hola'}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    await service.ask('  ¿Tengo paquetes?  ');

    final body = jsonDecode(utf8.decode(sent!.bodyBytes));
    expect(body, {
      'empresaId': 'ebb66ab7-db15-4267-9ef4-92abcb5273eb',
      'sessionId': '0x0200000027',
      'firstName': 'Temístocles',
      'lastName': 'Roa Pérez',
      'userAccount': 'BM-096791',
      'sucursalId': 'DO-BVT',
      'question': '¿Tengo paquetes?',
    });
  });

  test('keeps the accents the workflow answers with', () async {
    final service = _service(
      MockClient(
        (request) async => Response.bytes(
          utf8.encode(jsonEncode({'output': 'Tu sucursal está en La Julia.'})),
          200,
        ),
      ),
    );

    expect(
      (await service.ask('¿Dónde retiro?')).text,
      'Tu sucursal está en La Julia.',
    );
  });

  test('reads the answer out of the shapes n8n can return', () async {
    Future<String> answerFor(Object? body) async => (await _service(
          MockClient((request) async => Response(jsonEncode(body), 200)),
        ).ask('hola'))
            .text;

    expect(await answerFor({'output': 'uno'}), 'uno');
    expect(await answerFor([
      {'output': 'dos'},
    ]), 'dos');
    expect(await answerFor({'answer': 'tres'}), 'tres');
    expect(await answerFor('cuatro'), 'cuatro');
  });

  test('a body that is not JSON at all is still shown to the customer',
      () async {
    final service = _service(
      MockClient((request) async => Response('Estamos en mantenimiento.', 200)),
    );

    expect((await service.ask('hola')).text, 'Estamos en mantenimiento.');
  });

  test('refuses to ask without a session', () async {
    final service = _service(
      MockClient((request) async => Response('{}', 200)),
      identity: const AssistantIdentity(
        empresaId: 'empresa',
        sessionId: '',
        firstName: '',
        lastName: '',
        userAccount: '',
        sucursalId: '',
      ),
    );

    await expectLater(
      service.ask('¿Tengo paquetes?'),
      throwsA(isA<AssistantSignedOutException>()),
    );
  });

  test('an error status, an empty answer and a dropped connection all read as '
      'unavailable', () async {
    Future<void> expectUnavailable(MockClient client) => expectLater(
          _service(client).ask('hola'),
          throwsA(isA<AssistantUnavailableException>()),
        );

    await expectUnavailable(MockClient((request) async => Response('', 500)));
    await expectUnavailable(
      MockClient((request) async => Response(jsonEncode({'output': ''}), 200)),
    );
    await expectUnavailable(
      MockClient((request) async => throw ClientException('connection closed')),
    );
  });

  test("n8n's structured output parser nests the object under 'output'",
      () async {
    // Captured verbatim from the live workflow after the parser was added.
    const body =
        '{"output":{"output":"Su sucursal **DO.BVT** cierra a las **7:00 PM** '
        'de Lunes a Viernes y a las **4:00 PM** los Sábados.",'
        '"needs_human":false,"summary":""}}';
    final service = _service(
      MockClient(
        (request) async => Response.bytes(utf8.encode(body), 200),
      ),
    );

    final reply = await service.ask('¿A qué hora cierra mi sucursal?');

    expect(reply.text, startsWith('Su sucursal **DO.BVT** cierra'));
    expect(reply.needsHuman, isFalse);
  });

  test('the nested shape carries a handoff too', () async {
    final service = _service(
      MockClient(
        (request) async => Response(
          jsonEncode({
            'output': {
              'output': 'Le paso su caso a la sucursal.',
              'needs_human': true,
              'summary': 'Hola, soy Temistocles Roa, mi paquete llego roto.',
            },
          }),
          200,
        ),
      ),
    );

    final reply = await service.ask('hola');

    expect(reply.hasHandoff, isTrue);
    expect(reply.summary, startsWith('Hola, soy Temistocles Roa'));
  });

  test('a flat body still reads the same way', () async {
    final service = _service(
      MockClient(
        (request) async =>
            Response(jsonEncode({'output': 'Tienes 2 paquetes.'}), 200),
      ),
    );

    expect((await service.ask('hola')).text, 'Tienes 2 paquetes.');
  });

  group('the handoff fields', () {
    Future<AssistantReply> replyFor(Object? body) => _service(
          MockClient((request) async => Response(jsonEncode(body), 200)),
        ).ask('hola');

    test('are read when the workflow sends them', () async {
      final reply = await replyFor({
        'output': 'Lo siento, no puedo resolver eso.',
        'needs_human': true,
        'summary': 'Hola, mi paquete llegó roto y necesito ayuda.',
      });

      expect(reply.needsHuman, isTrue);
      expect(reply.summary, 'Hola, mi paquete llegó roto y necesito ayuda.');
      expect(reply.hasHandoff, isTrue);
    });

    test('default to no handoff when the workflow omits them', () async {
      final reply = await replyFor({'output': 'Tienes 2 paquetes.'});

      expect(reply.needsHuman, isFalse);
      expect(reply.summary, isEmpty);
      expect(reply.hasHandoff, isFalse);
    });

    test('survive a model that wrote the flag as a string', () async {
      final reply = await replyFor({
        'output': 'Te comunico con alguien.',
        'needs_human': 'true',
        'summary': 'Hola, quiero hablar con una persona.',
      });

      expect(reply.needsHuman, isTrue);
    });

    test('offer nothing when the flag is set but the summary is empty',
        () async {
      final reply = await replyFor({
        'output': 'Listo.',
        'needs_human': true,
        'summary': '   ',
      });

      expect(reply.needsHuman, isTrue);
      // Sending a person an empty message helps nobody.
      expect(reply.hasHandoff, isFalse);
    });
  });

  test('a body sent without a utf-8 header still yields its answer', () async {
    final service = _service(
      MockClient(
        (request) async => Response(
          latin1.decode(utf8.encode('{"output": "Tu paquete llegó."}')),
          200,
        ),
      ),
    );

    expect((await service.ask('hola')).text, isNotEmpty);
  });

  test('an empty question never reaches the network', () async {
    var called = false;
    final service = _service(
      MockClient((request) async {
        called = true;
        return Response('{}', 200);
      }),
    );

    await expectLater(
      service.ask('   '),
      throwsA(isA<AssistantUnavailableException>()),
    );
    expect(called, isFalse);
  });

  group('splitCustomerName', () {
    test('takes the first word as the given name', () {
      expect(
        splitCustomerName('Temístocles Roa Pérez'),
        (firstName: 'Temístocles', lastName: 'Roa Pérez'),
      );
    });

    test('leaves the family name empty rather than repeating one word', () {
      expect(
        splitCustomerName('Temístocles'),
        (firstName: 'Temístocles', lastName: ''),
      );
    });

    test('collapses the whitespace of a hand-typed record', () {
      expect(
        splitCustomerName('  Ana   María   Núñez '),
        (firstName: 'Ana', lastName: 'María Núñez'),
      );
    });

    test('survives an account with no name at all', () {
      expect(splitCustomerName(''), (firstName: '', lastName: ''));
    });
  });
}
