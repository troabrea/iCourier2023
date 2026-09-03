import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:icourier/services/assistant_service.dart';
import 'package:icourier/services/model/asistente_model.dart';
import 'package:icourier/services/model/assistant_settings.dart';

const _identity = AssistantIdentity(
  empresaId: 'ebb66ab7-db15-4267-9ef4-92abcb5273eb',
  sessionId: '0x0200000027',
  firstName: 'Temístocles',
  lastName: 'Roa Pérez',
  userAccount: 'BM-096791',
  sucursalId: 'DO-BVT',
);

AssistantService _service(
  Client client, {
  AssistantIdentity? identity,
  AssistantSettings settings = AssistantSettings.none,
}) =>
    AssistantService(
      client: client,
      endpoint: Uri.parse('https://example.test/assistant'),
      identity: () async => identity ?? _identity,
      settings: () async => settings,
    );

void main() {
  group('the courier record', () {
    test('routes the question to the workflow the courier configured',
        () async {
      Request? sent;
      final service = _service(
        MockClient((request) async {
          sent = request;
          return Response(jsonEncode({'output': 'Hola'}), 200);
        }),
        settings: AssistantSettings.parse(jsonEncode({
          'Name': 'Asistente',
          'ServiceSettings': {
            'ServiceUrl': 'https://n8n.example.test/webhook/tupaq',
            'ApiKey': 'tupaq-key',
          },
        })),
      );

      await service.ask('¿Tengo paquetes?');

      expect(sent!.url.toString(), 'https://n8n.example.test/webhook/tupaq');
      expect(sent!.headers['X-Api-Key'], 'tupaq-key');
    });

    test('falls back to the shared workflow while a record is still empty',
        () async {
      Request? sent;
      final service = _service(
        MockClient((request) async {
          sent = request;
          return Response(jsonEncode({'output': 'Hola'}), 200);
        }),
      );

      await service.ask('¿Tengo paquetes?');

      expect(sent!.url.toString(), 'https://example.test/assistant');
      expect(sent!.headers.containsKey('X-Api-Key'), isFalse);
    });

    test('never sends a key the courier left blank', () async {
      Request? sent;
      final service = _service(
        MockClient((request) async {
          sent = request;
          return Response(jsonEncode({'output': 'Hola'}), 200);
        }),
        settings: AssistantSettings.parse(jsonEncode({
          'ServiceSettings': {
            'ServiceUrl': 'https://n8n.example.test/webhook/tupaq',
            'ApiKey': '   ',
          },
        })),
      );

      await service.ask('¿Tengo paquetes?');

      expect(sent!.headers.containsKey('X-Api-Key'), isFalse);
    });

    test('a spent quota is told apart from a failure worth retrying', () async {
      final service = _service(
        MockClient((request) async => Response('rate limit reached', 429)),
      );

      try {
        await service.ask('¿Tengo paquetes?');
        fail('The question should have been refused.');
      } on AssistantQuotaException catch (error) {
        expect(error.scope, AssistantQuotaScope.unknown);
        expect(error.resetAt, isNull);
        expect(error.requestId, isNull);
      }
    });

    test('missing quota fields keep the refusal generic', () async {
      final service = _service(
        MockClient(
          (request) async => Response(jsonEncode({'error': {}}), 429),
        ),
      );

      try {
        await service.ask('¿Tengo paquetes?');
        fail('The question should have been refused.');
      } on AssistantQuotaException catch (error) {
        expect(error.scope, AssistantQuotaScope.unknown);
        expect(error.resetAt, isNull);
        expect(error.requestId, isNull);
      }
    });

    test('reads the daily session quota returned by the proxy', () async {
      final service = _service(
        MockClient(
          (request) async => Response(
            jsonEncode({
              'error': {
                'code': 'rate_limit_exceeded',
                'message': 'Se alcanzó el límite de solicitudes disponible.',
                'requestId': '8b49c78a-5f86-47ad-a60d-e8eb7522dd71',
                'scope': 'session_daily',
                'resetAt': '2026-08-22T04:00:00.000Z',
              },
            }),
            429,
          ),
        ),
      );

      try {
        await service.ask('¿Tengo paquetes?');
        fail('The question should have been refused.');
      } on AssistantQuotaException catch (error) {
        expect(error.scope, AssistantQuotaScope.sessionDaily);
        expect(error.resetAt, DateTime.utc(2026, 8, 22, 4));
        expect(
          error.requestId,
          '8b49c78a-5f86-47ad-a60d-e8eb7522dd71',
        );
      }
    });

    test('reads the company monthly quota returned by the proxy', () async {
      final service = _service(
        MockClient(
          (request) async => Response(
            jsonEncode({
              'error': {
                'code': 'rate_limit_exceeded',
                'requestId': '8b49c78a-5f86-47ad-a60d-e8eb7522dd71',
                'scope': 'company_monthly',
                'resetAt': '2026-09-01T04:00:00.000Z',
              },
            }),
            429,
          ),
        ),
      );

      try {
        await service.ask('¿Tengo paquetes?');
        fail('The question should have been refused.');
      } on AssistantQuotaException catch (error) {
        expect(error.scope, AssistantQuotaScope.companyMonthly);
        expect(error.resetAt, DateTime.utc(2026, 9, 1, 4));
        expect(
          error.requestId,
          '8b49c78a-5f86-47ad-a60d-e8eb7522dd71',
        );
      }
    });

    test('a refused payment is a spent quota too', () async {
      final service = _service(
        MockClient((request) async => Response('quota exhausted', 402)),
      );

      try {
        await service.ask('¿Tengo paquetes?');
        fail('The question should have been refused.');
      } on AssistantQuotaException catch (error) {
        expect(error.scope, AssistantQuotaScope.unknown);
        expect(error.resetAt, isNull);
        expect(error.requestId, isNull);
      }
    });

    test('every other bad status stays a retryable failure', () async {
      final service = _service(
        MockClient((request) async => Response('boom', 500)),
      );

      await expectLater(
        service.ask('¿Tengo paquetes?'),
        throwsA(isA<AssistantUnavailableException>()),
      );
    });
  });

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
    expect(
      sent!.headers['Accept'],
      'application/x-ndjson, application/json',
    );
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

  group('streaming replies', () {
    test('reassembles split UTF-8 chunks and returns final metadata', () async {
      final payload = [
        jsonEncode({'type': 'status', 'code': 'checking_packages'}),
        jsonEncode({'type': 'delta', 'text': 'Tu paquete lleg'}),
        jsonEncode({'type': 'delta', 'text': 'ó.'}),
        jsonEncode({
          'type': 'done',
          'source': 'get_paquetes',
          'needs_human': false,
          'summary': '',
        }),
        '',
      ].join('\n');
      final bytes = utf8.encode(payload);
      final splitInsideAccent = bytes.indexOf(0xc3) + 1;
      final service = _service(
        _ChunkedClient(
          chunks: [
            bytes.sublist(0, 17),
            bytes.sublist(17, splitInsideAccent),
            bytes.sublist(splitInsideAccent),
          ],
          headers: {'content-type': 'application/x-ndjson; charset=utf-8'},
        ),
      );

      final events = await service.askStream('¿Dónde está?').toList();

      expect(
        events.whereType<AssistantStreamStatus>().single.code,
        'checking_packages',
      );
      expect(
        events.whereType<AssistantTextDelta>().map((event) => event.text),
        ['Tu paquete lleg', 'ó.'],
      );
      final reply = events.whereType<AssistantReplyCompleted>().single.reply;
      expect(reply.text, 'Tu paquete llegó.');
      expect(reply.source, 'get_paquetes');
      expect(reply.needsHuman, isFalse);
    });

    test('accepts a full answer on the done event', () async {
      final service = _service(
        _ChunkedClient.ndjson([
          {'type': 'done', 'output': 'Respuesta completa.'},
        ]),
      );

      expect((await service.ask('hola')).text, 'Respuesta completa.');
    });

    test('rejects a stream that closes without a done event', () async {
      final service = _service(
        _ChunkedClient.ndjson([
          {'type': 'delta', 'text': 'Respuesta incompleta'},
        ]),
      );

      await expectLater(
        service.ask('hola'),
        throwsA(isA<AssistantUnavailableException>()),
      );
    });

    test('reads a quota failure emitted after the stream starts', () async {
      final service = _service(
        _ChunkedClient.ndjson([
          {
            'type': 'error',
            'code': 'rate_limit_exceeded',
            'scope': 'session_daily',
            'requestId': 'request-7',
          },
        ]),
      );

      try {
        await service.ask('hola');
        fail('The stream should have reported the spent quota.');
      } on AssistantQuotaException catch (error) {
        expect(error.scope, AssistantQuotaScope.sessionDaily);
        expect(error.requestId, 'request-7');
      }
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
    expect(
        await answerFor([
          {'output': 'dos'},
        ]),
        'dos');
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

  test(
      'an error status, an empty answer and a dropped connection all read as '
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
        '[{"output":{"output":"Su sucursal **DO.BVT** cierra a las **7:00 PM** '
        'de Lunes a Viernes y a las **4:00 PM** los Sábados.",'
        '"needs_human":false,"summary":"","source":"get_sucursales"}}]';
    final service = _service(
      MockClient(
        (request) async => Response.bytes(utf8.encode(body), 200),
      ),
    );

    final reply = await service.ask('¿A qué hora cierra mi sucursal?');

    expect(reply.text, startsWith('Su sucursal **DO.BVT** cierra'));
    expect(reply.source, 'get_sucursales');
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

  test('trims a source from a flat body', () async {
    final service = _service(
      MockClient(
        (request) async => Response(
          jsonEncode({
            'output': 'Tienes 2 paquetes.',
            'source': '  get_paquetes  ',
          }),
          200,
        ),
      ),
    );

    expect((await service.ask('hola')).source, 'get_paquetes');
  });

  test('defaults to an empty source for a legacy body', () async {
    final service = _service(
      MockClient(
        (request) async => Response(
          jsonEncode({'output': 'Tienes 2 paquetes.'}),
          200,
        ),
      ),
    );

    expect((await service.ask('hola')).source, isEmpty);
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

final class _ChunkedClient extends BaseClient {
  _ChunkedClient({
    required this.chunks,
    this.headers = const {},
  });

  factory _ChunkedClient.ndjson(List<Map<String, Object?>> events) {
    final body = '${events.map(jsonEncode).join('\n')}\n';
    return _ChunkedClient(
      chunks: [utf8.encode(body)],
      headers: {'content-type': 'application/x-ndjson; charset=utf-8'},
    );
  }

  final List<List<int>> chunks;
  final Map<String, String> headers;

  @override
  Future<StreamedResponse> send(BaseRequest request) async => StreamedResponse(
        Stream<List<int>>.fromIterable(chunks),
        200,
        headers: headers,
        request: request,
      );
}
