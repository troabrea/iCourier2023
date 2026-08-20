import 'package:flutter_test/flutter_test.dart';
import 'package:icourier/surveys/survey_launcher.dart';
import 'package:icourier/surveys/survey_prompt_coordinator.dart';

void main() {
  final invitation = SurveyInvitation(
    uri: Uri.parse('https://example.com/encuesta/customer-satisfaction'),
    activeThrough: DateTime(2026, 9, 30),
  );

  test('marks a survey handled after a successful browser handoff', () async {
    final store = _MemorySurveyPromptStore();
    final launcher = SurveyLauncher(
      store: store,
      launch: (uri) async => true,
    );

    expect(await launcher.open(invitation), isTrue);
    expect(store.answeredUrl, invitation.uri.toString());
  });

  test('does not mark a survey handled when the browser rejects it', () async {
    final store = _MemorySurveyPromptStore();
    final launcher = SurveyLauncher(
      store: store,
      launch: (uri) async => false,
    );

    expect(await launcher.open(invitation), isFalse);
    expect(store.answeredUrl, isNull);
  });
}

final class _MemorySurveyPromptStore implements SurveyPromptStore {
  String? answeredUrl;

  @override
  Future<void> markAnswered(String url) async => answeredUrl = url;

  @override
  Future<String?> readAnsweredUrl() async => answeredUrl;

  @override
  Future<SurveySnooze?> readSnooze() async => null;

  @override
  Future<void> snooze(String url, DateTime until) async {}
}
