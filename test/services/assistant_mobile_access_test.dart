import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:icourier/apps/appinfo.dart';
import 'package:icourier/apps/bmcargo/appinfo_bmcargo.dart';
import 'package:icourier/services/courier_service.dart';
import 'package:icourier/services/model/empresa.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CourierService courier;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GetIt.I.registerSingleton<AppInfo>(BmcargoAppInfo());
    courier = CourierService();
  });

  tearDown(() async => GetIt.I.reset());

  test('a late approval cannot show the chat for a different account',
      () async {
    final firstReply = Completer<http.Response>();
    final firstRequest = Completer<void>();
    final client = MockClient((request) async {
      if (request.method == 'GET') {
        return _company(everyone: false);
      }
      expect(request.method, 'POST');
      expect(request.url, Uri.parse(_accessUrl));
      expect(request.headers['x-api-key'], 'test-key');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['empresaId'], courier.companyId);
      if (body['userAccount'] == 'BM-001') {
        firstRequest.complete();
        return firstReply.future;
      }
      expect(body, {'empresaId': courier.companyId, 'userAccount': 'BM-002'});
      return http.Response('{"enabled":false}', 200);
    });

    await http.runWithClient(() async {
      await courier.getEmpresa();
      expect(courier.assistantEnabled.value, isFalse);

      final firstLookup = courier.setAssistantAccount(' BM-001 ');
      await firstRequest.future;
      await courier.setAssistantAccount('BM-002');
      firstReply.complete(http.Response('{"enabled":true}', 200));
      await firstLookup;

      expect(courier.assistantEnabled.value, isFalse);
    }, () => client);
  });

  test('refresh updates pilot visibility and logout clears it', () async {
    var response = http.Response('{"enabled":true}', 200);
    var checks = 0;
    final client = MockClient((request) async {
      if (request.method == 'GET') {
        return _company(everyone: false);
      }
      checks++;
      return response;
    });

    await http.runWithClient(() async {
      await courier.getEmpresa();
      await courier.setAssistantAccount('BM-001');
      expect(courier.assistantEnabled.value, isTrue);

      response = http.Response('{"enabled":true}', 503);
      await courier.refreshAssistantAccess();
      expect(courier.assistantEnabled.value, isFalse);

      response = http.Response('{"enabled":true}', 200);
      await courier.refreshAssistantAccess();
      expect(courier.assistantEnabled.value, isTrue);

      await courier.setAssistantAccount('');
      expect(courier.assistantEnabled.value, isFalse);
      expect(checks, 3);
    }, () => client);
  });

  test('the global switch takes effect without a pilot lookup', () async {
    var everyone = false;
    var checks = 0;
    final client = MockClient((request) async {
      if (request.method == 'GET') {
        return _company(everyone: everyone);
      }
      checks++;
      return http.Response('{"enabled":false}', 200);
    });

    await http.runWithClient(() async {
      await courier.getEmpresa();
      await courier.setAssistantAccount('BM-001');
      expect(courier.assistantEnabled.value, isFalse);

      everyone = true;
      await courier.getEmpresa(forceFirstTime: true);
      expect(courier.assistantEnabled.value, isTrue);

      await courier.setAssistantAccount('BM-002');
      await courier.refreshAssistantAccess();
      expect(courier.assistantEnabled.value, isTrue);
      expect(checks, 1);
    }, () => client);
  });
}

const _accessUrl = 'https://portal.example.test/api/assistant/mobile-access';

http.Response _company({required bool everyone}) => http.Response(
      jsonEncode({
        ...Empresa.empty().toJson(),
        'hasChatBotModule': everyone,
        'chatBotSettings': jsonEncode({
          'MobileAccessUrl': _accessUrl,
          'ServiceSettings': {'ApiKey': 'test-key'},
        }),
      }),
      200,
    );
