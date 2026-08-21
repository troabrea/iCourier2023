import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:icourier/services/model/assistant_settings.dart';
import 'package:icourier/services/model/empresa.dart';

const _record = '''
{
    "Name" : "Asistente",
    "ServiceSettings": {
        "ServiceUrl": "https://n8n.example.test/webhook/courier/assistant",
        "ApiKey": "tupaq-2f8c",
        "SessionDailyRateLimit": 30,
        "CompanyMonthlyRateLimit": 5000
    }
}
''';

void main() {
  test('reads the record the portal writes', () {
    final settings = AssistantSettings.parse(_record);

    expect(settings.name, 'Asistente');
    expect(
      settings.endpoint.toString(),
      'https://n8n.example.test/webhook/courier/assistant',
    );
    expect(settings.apiKey, 'tupaq-2f8c');
    expect(settings.sessionDailyLimit, 30);
    expect(settings.companyMonthlyLimit, 5000);
  });

  test('reads the same record however the backend cased its keys', () {
    final settings = AssistantSettings.parse(jsonEncode({
      'name': 'Asistente',
      'serviceSettings': {
        'serviceUrl': 'https://n8n.example.test/webhook/x',
        'apiKey': 'k',
      },
    }));

    expect(settings.endpoint.toString(), 'https://n8n.example.test/webhook/x');
    expect(settings.apiKey, 'k');
  });

  test('a record saved with a trailing comma costs the settings, not the app',
      () {
    expect(
      AssistantSettings.parse('{"ServiceSettings": {"ApiKey": "k",}}'),
      same(AssistantSettings.none),
    );
  });

  test('a courier who filled nothing in reads as no settings at all', () {
    expect(AssistantSettings.parse(''), same(AssistantSettings.none));
    expect(AssistantSettings.parse('   '), same(AssistantSettings.none));
    expect(AssistantSettings.parse('null'), same(AssistantSettings.none));
    expect(AssistantSettings.parse('[]'), same(AssistantSettings.none));
  });

  test('an unset limit reads as uncapped rather than as zero', () {
    final settings = AssistantSettings.parse(jsonEncode({
      'ServiceSettings': {
        'SessionDailyRateLimit': -1,
        'CompanyMonthlyRateLimit': null,
      },
    }));

    expect(settings.sessionDailyLimit, AssistantSettings.unlimited);
    expect(settings.companyMonthlyLimit, AssistantSettings.unlimited);
  });

  test('a limit typed into a text field is still a number', () {
    final settings = AssistantSettings.parse(jsonEncode({
      'ServiceSettings': {'SessionDailyRateLimit': ' 25 '},
    }));

    expect(settings.sessionDailyLimit, 25);
  });

  test('a url that is not a web address is not somewhere to send a question',
      () {
    for (final url in const [
      '',
      '   ',
      'n8n.example.test/webhook',
      'javascript:alert(1)',
      'file:///etc/passwd',
    ]) {
      final settings = AssistantSettings.parse(jsonEncode({
        'ServiceSettings': {'ServiceUrl': url},
      }));
      expect(settings.endpoint, isNull, reason: url);
    }
  });

  test('the abandoned chatbot record reads as a courier with nothing set up',
      () {
    // Four couriers still hold this in the column the assistant now uses. It
    // has to degrade to "not configured", not to a broken assistant.
    final settings = AssistantSettings.parse(jsonEncode({
      'BotName': 'BoxPaq Courier',
      'ChatTextOptions': {'Rastreo': 'Rastrear Paquete'},
      'ChatConfig': {'BlackListRole': 'Admin', 'UnAssignMinutesThreshold': 30},
    }));

    expect(settings.endpoint, isNull);
    expect(settings.apiKey, '');
    expect(settings.sessionDailyLimit, AssistantSettings.unlimited);
  });

  test('the module rides on the columns the API already answers with', () {
    final company = Empresa.fromJson(jsonDecode(jsonEncode({
      'registroID': '1',
      'nombre': 'TUPAQ',
      'dominio': 'tupaq',
      'urlServidor': '',
      'webServiceURL': '',
      'registerURL': '',
      'tokenID': '',
      'hasPointsModule': false,
      'hasAutobuses': false,
      'hasPreguntas': true,
      'hasPaymentsModule': false,
      'hasNotifyModule': false,
      'hasDelivery': false,
      'minDistanceToNotify': 0,
      'erp': 0,
      'deleted': false,
      'hasChatBotModule': true,
      'chatBotSettings': _record,
    })) as Map<String, dynamic>);

    expect(company.hasAssistantModule, isTrue);
    expect(
      AssistantSettings.parse(company.assistantSettings).apiKey,
      'tupaq-2f8c',
    );
  });

  test('the columns the API will grow later are read too, when they arrive',
      () {
    final company = Empresa.fromJson(jsonDecode(jsonEncode({
      'registroID': '1',
      'nombre': 'TUPAQ',
      'dominio': 'tupaq',
      'urlServidor': '',
      'webServiceURL': '',
      'registerURL': '',
      'tokenID': '',
      'hasPointsModule': false,
      'hasAutobuses': false,
      'hasPreguntas': true,
      'hasPaymentsModule': false,
      'hasNotifyModule': false,
      'hasDelivery': false,
      'minDistanceToNotify': 0,
      'erp': 0,
      'deleted': false,
      'hasAssistantModule': true,
      'assistantSettings': _record,
    })) as Map<String, dynamic>);

    expect(company.hasAssistantModule, isTrue);
    expect(
      AssistantSettings.parse(company.assistantSettings).apiKey,
      'tupaq-2f8c',
    );
  });

  test('a company record older than the module reads as a courier without it',
      () {
    final company = Empresa.fromJson(jsonDecode('''
      {
        "registroID": "1", "nombre": "BM Cargo", "dominio": "bmcargo",
        "urlServidor": "", "webServiceURL": "", "registerURL": "",
        "tokenID": "", "hasPointsModule": false, "hasAutobuses": false,
        "hasPreguntas": true, "hasPaymentsModule": false,
        "hasNotifyModule": false, "hasDelivery": false,
        "minDistanceToNotify": 0, "erp": 0, "deleted": false
      }
    ''') as Map<String, dynamic>);

    expect(company.hasAssistantModule, isFalse);
    expect(company.assistantSettings, '');
  });

  test('the module and its record survive a round trip through toJson', () {
    final company = Empresa.empty()
      ..hasAssistantModule = true
      ..assistantSettings = _record;

    final restored = Empresa.fromJson(company.toJson());

    expect(restored.hasAssistantModule, isTrue);
    expect(
      AssistantSettings.parse(restored.assistantSettings).apiKey,
      'tupaq-2f8c',
    );
  });
}
