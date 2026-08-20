import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icourier/surveys/survey_prompt_cue.dart';

import '../helpers/brand_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    initializeTestTranslations();
    await loadBrandFonts();
  });

  testWidgets('shows a compact invitation with both decisions', (tester) async {
    var answered = false;
    var postponed = false;
    await tester.pumpWidget(
      brandTestApp(
        config: loadTestBrand('bmcargo'),
        child: SurveyPromptCue(
          onAnswer: () => answered = true,
          onPostpone: () => postponed = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tu opinión nos ayuda'), findsOneWidget);
    expect(find.text('Tenemos una encuesta breve para ti.'), findsOneWidget);

    await tester.tap(find.text('Más tarde'));
    await tester.tap(find.text('Responder'));

    expect(postponed, isTrue);
    expect(answered, isTrue);
  });

  testWidgets('supports 200% text scaling without overflow', (tester) async {
    await tester.pumpWidget(
      brandTestApp(
        config: loadTestBrand('fixocargo'),
        textScaler: const TextScaler.linear(2),
        child: SurveyPromptCue(
          onAnswer: () {},
          onPostpone: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('offers subtle manual access from notifications', (tester) async {
    var opened = false;
    await tester.pumpWidget(
      brandTestApp(
        config: loadTestBrand('bmcargo'),
        textScaler: const TextScaler.linear(2),
        child: SurveyNotificationAction(onOpen: () => opened = true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tu opinión nos ayuda'), findsOneWidget);
    expect(find.text('Abrir encuesta'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Abrir encuesta'));
    expect(opened, isTrue);
  });

  testWidgets('matches the notification center action', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 180));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      brandTestApp(
        config: loadTestBrand('fixocargo'),
        child: RepaintBoundary(
          key: const ValueKey('survey-notification-action'),
          child: SurveyNotificationAction(onOpen: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const ValueKey('survey-notification-action')),
      matchesGoldenFile('goldens/survey_notification_action_fixocargo.png'),
    );
  });

  testWidgets('matches the floating mobile cue', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      brandTestApp(
        config: loadTestBrand('fixocargo'),
        child: const SizedBox.shrink(),
      ),
    );
    final scaffoldContext = tester.element(find.byType(Scaffold));
    final messenger = tester.state<ScaffoldMessengerState>(
      find.byType(ScaffoldMessenger),
    );
    messenger.showSnackBar(
      buildSurveyPromptSnackBar(
        scaffoldContext,
        onAnswer: () {},
        onPostpone: () {},
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(SurveyPromptCue), findsOneWidget);

    await expectLater(
      find.byType(SurveyPromptCue),
      matchesGoldenFile('goldens/survey_prompt_cue_fixocargo.png'),
    );
  });
}
