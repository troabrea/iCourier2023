import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:icourier/services/model/empresa.dart';
import 'package:icourier/surveys/survey_prompt_coordinator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final now = DateTime(2026, 8, 20, 10);
  const url = 'https://example.com/encuesta/customer-satisfaction';

  test('offers an active survey through the end of its configured date',
      () async {
    final store = _MemorySurveyPromptStore();
    final coordinator = SurveyPromptCoordinator(
      loadCompany: () async => _company(url: url, activeUntil: '2026-08-20'),
      store: store,
      clock: () => DateTime(2026, 8, 20, 23, 59),
    );

    final invitation = await coordinator.findInvitation();

    expect(invitation?.uri.toString(), url);
  });

  test('does not offer expired or invalid surveys', () async {
    final store = _MemorySurveyPromptStore();
    final expired = SurveyPromptCoordinator(
      loadCompany: () async => _company(url: url, activeUntil: '2026-08-19'),
      store: store,
      clock: () => now,
    );
    final invalid = SurveyPromptCoordinator(
      loadCompany: () async => _company(
        url: 'not-a-survey-url',
        activeUntil: '2026-09-30',
      ),
      store: store,
      clock: () => now,
    );

    expect(await expired.findInvitation(), isNull);
    expect(await invalid.findInvitation(), isNull);
  });

  test('postpones the same survey for three days', () async {
    var currentTime = now;
    final store = _MemorySurveyPromptStore();
    final coordinator = SurveyPromptCoordinator(
      loadCompany: () async => _company(url: url, activeUntil: '2026-09-30'),
      store: store,
      clock: () => currentTime,
    );
    final invitation = (await coordinator.findInvitation())!;

    await coordinator.postpone(invitation);
    currentTime = now.add(const Duration(days: 2, hours: 23));
    expect(await coordinator.findInvitation(), isNull);

    currentTime = now.add(const Duration(days: 3));
    expect(await coordinator.findInvitation(), isNotNull);
  });

  test('an answered survey stays hidden but a new URL is offered', () async {
    var currentUrl = url;
    final store = _MemorySurveyPromptStore();
    final coordinator = SurveyPromptCoordinator(
      loadCompany: () async => _company(
        url: currentUrl,
        activeUntil: '2026-09-30',
      ),
      store: store,
      clock: () => now,
    );
    final invitation = (await coordinator.findInvitation())!;

    await coordinator.markAnswered(invitation);
    expect(await coordinator.findInvitation(), isNull);
    expect(
      SurveyInvitation.activeFor(
        _company(url: currentUrl, activeUntil: '2026-09-30'),
        now,
      ),
      isNotNull,
      reason: 'Manual access must remain available in notifications.',
    );

    currentUrl = 'https://example.com/encuesta/new-survey';
    expect(await coordinator.findInvitation(), isNotNull);
  });

  test('a new survey URL is not blocked by an older snooze', () async {
    var currentUrl = url;
    final store = _MemorySurveyPromptStore();
    final coordinator = SurveyPromptCoordinator(
      loadCompany: () async => _company(
        url: currentUrl,
        activeUntil: '2026-09-30',
      ),
      store: store,
      clock: () => now,
    );
    await coordinator.postpone((await coordinator.findInvitation())!);

    currentUrl = 'https://example.com/encuesta/new-survey';

    expect(await coordinator.findInvitation(), isNotNull);
  });

  test('migrates the survey handled by the previous app version', () async {
    const contentKey = 'content123lastEncuestaUrl';
    SharedPreferences.setMockInitialValues({
      'lastEncuestaUrl': jsonEncode({
        'content': contentKey,
        'type': 'type123lastEncuestaUrl',
      }),
      contentKey: url,
      'type123lastEncuestaUrl': 'String',
    });
    final preferences = await SharedPreferences.getInstance();
    final store = SharedPreferencesSurveyPromptStore(preferences);

    expect(await store.readAnsweredUrl(), url);
    expect(
      preferences.getString(
        SharedPreferencesSurveyPromptStore.answeredUrlKey,
      ),
      url,
    );
  });
}

final class _MemorySurveyPromptStore implements SurveyPromptStore {
  String? answeredUrl;
  SurveySnooze? snoozeValue;

  @override
  Future<void> markAnswered(String url) async {
    answeredUrl = url;
    snoozeValue = null;
  }

  @override
  Future<String?> readAnsweredUrl() async => answeredUrl;

  @override
  Future<SurveySnooze?> readSnooze() async => snoozeValue;

  @override
  Future<void> snooze(String url, DateTime until) async {
    snoozeValue = SurveySnooze(url: url, until: until);
  }
}

Empresa _company({required String url, required String activeUntil}) => Empresa(
      registroId: 'company',
      nombre: 'Courier',
      dominio: 'courier',
      mision: '',
      vision: '',
      correoServicio: '',
      correoVentas: '',
      paginaWeb: '',
      telefonoOficina: '',
      telefonoVentas: '',
      twitter: '',
      facebook: '',
      instagram: '',
      urlServidor: '',
      webServiceUrl: '',
      registerUrl: '',
      tokenId: '',
      calculadoraDesde: '',
      calculadoraHasta: '',
      calculadoraProducto: '',
      hasPointsModule: false,
      hasAutobuses: false,
      hasPreguntas: false,
      hasPaymentsModule: false,
      hasNotifyModule: false,
      hasDelivery: false,
      minDistanceToNotify: 0,
      erp: 0,
      deleted: false,
      clientId: '',
      clientSecret: '',
      pushHubEndpoint: url,
      pushHubName: activeUntil,
      options: '',
    );
