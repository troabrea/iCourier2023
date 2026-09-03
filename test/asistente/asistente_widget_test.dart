import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:event/event.dart' as event;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/apps/appinfo.dart';
import 'package:icourier/apps/bmcargo/appinfo_bmcargo.dart';
import 'package:icourier/asistente/asistente.dart';
import 'package:icourier/asistente/assistant_avatar.dart';
import 'package:icourier/asistente/assistant_conversation.dart';
import 'package:icourier/asistente/bloc/asistente_bloc.dart';
import 'package:icourier/helpers/contact_action.dart';
import 'package:icourier/design_system/brand_foundations.dart';
import 'package:icourier/design_system/motion_components.dart';
import 'package:icourier/services/app_events.dart';
import 'package:icourier/services/assistant_service.dart';
import 'package:icourier/services/courier_service.dart';
import 'package:icourier/services/model/asistente_model.dart';
import 'package:icourier/services/model/empresa.dart';
import 'package:icourier/services/model/login_model.dart';
import 'package:icourier/theme/brand_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/brand_test_app.dart';

/// The answer the live workflow returns for a branch question, trimmed to the
/// two branches that fit one screen.
const _branchAnswer = '''
¡Claro, Temístocles! Aquí tienes nuestras sucursales y sus horarios:

**Santo Domingo:**

*   **La Julia:** Av. Winston Churchill No 51, Ens La Julia. Horario: L-V 9:00am a 7:00pm, S 9:00am a 4:00pm.
*   **Sambil:** Local SM-5, primer nivel, con acceso desde la San Martín. Horario: L-S 10:00am a 9:00pm.

¿Quieres que te diga cuál te queda más cerca?
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _FakeAssistant assistant;
  late _AssistantCourierService courier;

  setUpAll(() async {
    initializeTestTranslations();
    await loadBrandFonts();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GetIt.I.reset();
    GetIt.I.registerSingleton<AppInfo>(BmcargoAppInfo());
    GetIt.I.registerSingleton<BrandConfig>(loadTestBrand('bmcargo'));
    GetIt.I.registerSingleton<event.Event<LoginChanged>>(
      event.Event<LoginChanged>(),
    );
    courier = _AssistantCourierService();
    GetIt.I.registerSingleton<CourierService>(courier);
    assistant = _FakeAssistant();
    GetIt.I.registerSingleton<AssistantService>(assistant);
    GetIt.I.registerSingleton<AssistantConversation>(AssistantConversation());
  });

  tearDown(() => GetIt.I.reset());

  Future<void> open(WidgetTester tester, {TextScaler? textScaler}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      brandTestApp(
        config: GetIt.I<BrandConfig>(),
        textScaler: textScaler ?? TextScaler.noScaling,
        child: const AsistentePage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('greets the customer by name and offers real questions',
      (tester) async {
    await open(tester);

    expect(find.text('Hola, Temístocles.'), findsOneWidget);
    expect(find.text('BM Cargo'), findsOneWidget);
    final hero = tester.widget<Hero>(find.byType(Hero));
    expect(hero.tag, AssistantAvatar.heroTag);
    expect(
      tester
          .widget<AssistantAvatarEntrance>(
            find.byType(AssistantAvatarEntrance),
          )
          .rotate,
      isTrue,
    );
    expect(
      tester.widget<AssistantAvatar>(find.byType(AssistantAvatar)).size,
      96,
    );
    final introduction = tester.widget<Text>(
      find.byKey(const ValueKey('assistant-introduction')),
    );
    expect(
      introduction.textSpan!.toPlainText(),
      'Soy BM Cargo, pregúntame por tus paquetes, las sucursales, '
      'los servicios o el costo de un envío.',
    );
    expect(find.text('¿Tengo paquetes disponibles?'), findsOneWidget);
    expect(find.text('¿Qué servicios ofrecen?'), findsOneWidget);
    expect(find.text('Escribe tu pregunta'), findsOneWidget);
    // The header carries no contact action: a person is offered in the answer
    // that needs one, not as standing chrome.
    expect(find.byType(BrandContactAction), findsNothing);
    // Nothing to clear yet, so nothing to reset.
    expect(find.byIcon(Icons.restart_alt_rounded), findsNothing);
    expect(
      find.textContaining('Las respuestas las escribe un asistente automático'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(AsistentePage),
      matchesGoldenFile('goldens/asistente_inicio.png'),
    );
  });

  testWidgets('uses the configured assistant name and avatar', (tester) async {
    courier
      ..assistantName = 'Mía'
      ..avatarSvg =
          "<svg viewBox='0 0 24 24'><circle cx='12' cy='12' r='8'/></svg>";

    await open(tester);

    expect(find.text('Mía'), findsOneWidget);
    final avatar = tester.widget<AssistantAvatar>(
      find.byType(AssistantAvatar),
    );
    expect(avatar.semanticLabel, 'Mía');
    expect(avatar.avatarSvg, contains('<circle'));
    final introduction = tester.widget<Text>(
      find.byKey(const ValueKey('assistant-introduction')),
    );
    final spans = (introduction.textSpan! as TextSpan).children!;
    final nameSpan = spans[1] as TextSpan;
    expect(nameSpan.text, 'Mía');
    expect(nameSpan.style!.fontWeight, FontWeight.w700);
  });

  testWidgets('falls back to the bundled avatar for malformed SVG',
      (tester) async {
    courier.avatarSvg = '<svg';

    await open(tester);

    final avatar = find.byType(AssistantAvatar);
    expect(
      find.descendant(of: avatar, matching: find.byType(BrandGlyph)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the question on screen while the answer is prepared',
      (tester) async {
    await open(tester);

    await tester.tap(find.text('¿Tengo paquetes disponibles?'));
    await tester.pump();

    expect(find.text('¿Tengo paquetes disponibles?'), findsOneWidget);
    expect(find.text('Preparando tu respuesta.'), findsOneWidget);
    await expectLater(
      find.byType(AsistentePage),
      matchesGoldenFile('goldens/asistente_esperando.png'),
    );

    assistant.pending!.complete(const AssistantReply(
        text: 'Tienes 2 paquetes disponibles para retiro.'));
    await tester.pumpAndSettle();

    expect(find.text('Preparando tu respuesta.'), findsNothing);
  });

  testWidgets('admits when the wait runs long', (tester) async {
    await open(tester);

    await tester.tap(find.text('¿Tengo paquetes disponibles?'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 11));

    expect(
      find.text(
          'Esto está tardando un poco más de lo normal. Sigo trabajando.'),
      findsOneWidget,
    );

    assistant.pending!.complete(const AssistantReply(text: 'Listo.'));
    await tester.pumpAndSettle();
  });

  testWidgets('renders the answer as a document with its shortcuts',
      (tester) async {
    await open(tester);

    await tester.enterText(
        find.byType(TextField), '¿Dónde están sus oficinas?');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    assistant.pending!.complete(const AssistantReply(text: _branchAnswer));
    await tester.pumpAndSettle();

    expect(find.text('¿Dónde están sus oficinas?'), findsOneWidget);
    expect(find.text('Ver sucursales'), findsOneWidget);
    expect(
      find.textContaining('Verifica los datos importantes con tu sucursal'),
      findsOneWidget,
    );
    expect(find.textContaining('Av. Winston Churchill'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(AsistentePage),
      matchesGoldenFile('goldens/asistente_respuesta.png'),
    );
  });

  testWidgets('uses reply source before the answer wording for shortcuts',
      (tester) async {
    await open(tester);

    await tester.enterText(find.byType(TextField), '¿Qué recibí en agosto?');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    assistant.pending!.complete(
      const AssistantReply(
        text: 'Recibiste seis paquetes en agosto.',
        source: 'get_historico',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('asistente_ir_historico'.tr()), findsOneWidget);
    expect(find.text('asistente_ir_paquetes'.tr()), findsNothing);
  });

  testWidgets('indexes earlier questions once there is more than one',
      (tester) async {
    await open(tester);

    Future<void> ask(String question, String answer) async {
      await tester.enterText(find.byType(TextField), question);
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
      assistant.pending!.complete(AssistantReply(text: answer));
      await tester.pumpAndSettle();
    }

    await ask('¿Tengo paquetes?', 'Tienes 2 paquetes disponibles.');
    await ask('¿Dónde están sus oficinas?', _branchAnswer);

    expect(find.text('¿Tengo paquetes?'), findsOneWidget);
    await expectLater(
      find.byType(AsistentePage),
      matchesGoldenFile('goldens/asistente_historial.png'),
    );

    await tester.tap(find.text('¿Tengo paquetes?'));
    await tester.pumpAndSettle();

    expect(find.text('Tienes 2 paquetes disponibles.'), findsOneWidget);
  });

  testWidgets('an answer read again does not replay its arrival',
      (tester) async {
    await open(tester);

    Future<void> ask(String question, String answer) async {
      await tester.enterText(find.byType(TextField), question);
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
      assistant.pending!.complete(AssistantReply(text: answer));
      await tester.pumpAndSettle();
    }

    await ask('¿Tengo paquetes?', 'Tienes 2 paquetes disponibles.');
    await ask('¿Dónde están sus oficinas?', _branchAnswer);

    // Arriving is the authored moment; going back to read is not.
    expect(find.byType(BrandManifestReveal), findsWidgets);
    await tester.tap(find.text('¿Tengo paquetes?'));
    await tester.pumpAndSettle();

    expect(find.byType(BrandManifestReveal), findsNothing);
    expect(find.text('Tienes 2 paquetes disponibles.'), findsOneWidget);
  });

  testWidgets('the conversation survives leaving the screen and coming back',
      (tester) async {
    await open(tester);

    await tester.enterText(find.byType(TextField), '¿Tengo paquetes?');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    assistant.pending!
        .complete(const AssistantReply(text: 'Tienes 2 paquetes disponibles.'));
    await tester.pumpAndSettle();

    // A shortcut into a tab closes this screen. Reopening it must resume the
    // conversation rather than greet the customer again.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await open(tester);

    expect(find.text('Tienes 2 paquetes disponibles.'), findsOneWidget);
    expect(find.text('Hola, Temístocles.'), findsNothing);
    // Resuming is not an arrival, so the reveal does not run again.
    expect(find.byType(BrandManifestReveal), findsNothing);
  });

  testWidgets('another account never sees the previous conversation',
      (tester) async {
    await open(tester);

    await tester.enterText(find.byType(TextField), '¿Tengo paquetes?');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    assistant.pending!
        .complete(const AssistantReply(text: 'Tienes 2 paquetes disponibles.'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    assistant.account = 'BM-000001';
    await open(tester);

    expect(find.text('Tienes 2 paquetes disponibles.'), findsNothing);
    expect(find.text('Hola, Temístocles.'), findsOneWidget);
  });

  testWidgets('offers a person when the workflow asks for one', (tester) async {
    await open(tester);

    await tester.enterText(find.byType(TextField), 'Mi paquete llegó roto');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    assistant.pending!.complete(
      const AssistantReply(
        text: 'Lamento mucho lo ocurrido. Esto lo tiene que ver una persona.',
        needsHuman: true,
        summary: 'Hola, mi paquete WR010035050937 llegó roto y necesito ayuda.',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('asistente_humano_card_titulo'.tr()), findsOneWidget);
    expect(find.text('asistente_humano_escribir'.tr()), findsOneWidget);
    // The person is the primary action; any screen shortcut steps down to an
    // outline so the two are not competing for the same tap.
    expect(find.byType(BrandPrimaryButton), findsOneWidget);
  });

  testWidgets('an ordinary answer offers no person', (tester) async {
    await open(tester);

    await tester.tap(find.text('¿Tengo paquetes disponibles?'));
    await tester.pump();
    assistant.pending!.complete(
      const AssistantReply(text: 'Tienes 2 paquetes disponibles.'),
    );
    await tester.pumpAndSettle();

    expect(find.text('asistente_humano_escribir'.tr()), findsNothing);
  });

  testWidgets('a flag with no summary offers nothing to send', (tester) async {
    await open(tester);

    await tester.tap(find.text('¿Tengo paquetes disponibles?'));
    await tester.pump();
    assistant.pending!.complete(
      const AssistantReply(text: 'Listo.', needsHuman: true),
    );
    await tester.pumpAndSettle();

    expect(find.text('asistente_humano_escribir'.tr()), findsNothing);
  });

  testWidgets('starting over clears the conversation, once confirmed',
      (tester) async {
    await open(tester);

    await tester.tap(find.text('¿Tengo paquetes disponibles?'));
    await tester.pump();
    assistant.pending!.complete(
      const AssistantReply(text: 'Tienes 2 paquetes disponibles.'),
    );
    await tester.pumpAndSettle();

    final reset = find.byIcon(Icons.restart_alt_rounded);
    expect(reset, findsOneWidget);

    // Backing out of the dialog leaves the conversation alone.
    await tester.tap(reset);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Tienes 2 paquetes disponibles.'), findsOneWidget);

    await tester.tap(reset);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Borrar'));
    await tester.pumpAndSettle();

    expect(find.text('Tienes 2 paquetes disponibles.'), findsNothing);
    expect(find.text('Hola, Temístocles.'), findsOneWidget);
    expect(find.byIcon(Icons.restart_alt_rounded), findsNothing);
  });

  testWidgets('a cleared conversation does not come back on reopening',
      (tester) async {
    await open(tester);

    await tester.tap(find.text('¿Tengo paquetes disponibles?'));
    await tester.pump();
    assistant.pending!.complete(
      const AssistantReply(text: 'Tienes 2 paquetes disponibles.'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.restart_alt_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Borrar'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await open(tester);

    expect(find.text('Hola, Temístocles.'), findsOneWidget);
  });

  testWidgets('names the problem and the recovery when the webhook is down',
      (tester) async {
    await open(tester);

    await tester.tap(find.text('¿Tengo paquetes disponibles?'));
    await tester.pump();
    assistant.pending!.completeError(const AssistantUnavailableException());
    await tester.pumpAndSettle();

    expect(
      find.text(
        'No pude traer la respuesta. Revisa tu conexión e inténtalo otra vez.',
      ),
      findsOneWidget,
    );

    assistant.answers.add('Tienes 2 paquetes disponibles.');
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Tienes 2 paquetes disponibles.'), findsOneWidget);
  });

  testWidgets('a daily quota offers help without exposing the allowance',
      (tester) async {
    await open(tester);

    await tester.tap(find.text('¿Tengo paquetes disponibles?'));
    await tester.pump();
    assistant.pending!.completeError(
      AssistantQuotaException(
        scope: AssistantQuotaScope.sessionDaily,
        resetAt: DateTime.utc(2026, 8, 22, 4),
        requestId: '8b49c78a-5f86-47ad-a60d-e8eb7522dd71',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('asistente_no_puedo_responder_ahora'.tr()),
      findsOneWidget,
    );
    expect(find.textContaining('límite'), findsNothing);
    expect(find.text('asistente_humano_escribir'.tr()), findsOneWidget);
    expect(find.text('asistente_ir_faq'.tr()), findsOneWidget);
    expect(find.text('Reintentar'), findsNothing);
    expect(find.byType(TextField), findsNothing);

    final bloc = BlocProvider.of<AsistenteBloc>(
      tester.element(
        find.byType(BlocBuilder<AsistenteBloc, AsistenteState>),
      ),
    );
    bloc.add(const AssistantQuestionAsked('Otra pregunta'));
    await tester.pump();
    expect(assistant.askCount, 1);

    bloc.add(const AssistantConversationCleared());
    await tester.pump();
    expect(
      find.text('asistente_no_puedo_responder_ahora'.tr()),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('a monthly quota uses the same customer-friendly recovery',
      (tester) async {
    await open(tester);

    await tester.tap(find.text('¿Tengo paquetes disponibles?'));
    await tester.pump();
    assistant.pending!.completeError(
      const AssistantQuotaException(
        scope: AssistantQuotaScope.companyMonthly,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('asistente_no_puedo_responder_ahora'.tr()),
      findsOneWidget,
    );
    expect(find.textContaining('mensual'), findsNothing);
    expect(find.text('asistente_humano_escribir'.tr()), findsOneWidget);
    expect(find.text('asistente_ir_faq'.tr()), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('an unidentified quota gets the same neutral explanation',
      (tester) async {
    await open(tester);

    await tester.tap(find.text('¿Tengo paquetes disponibles?'));
    await tester.pump();
    assistant.pending!.completeError(const AssistantQuotaException());
    await tester.pumpAndSettle();

    expect(
      find.text('asistente_no_puedo_responder_ahora'.tr()),
      findsOneWidget,
    );
    expect(find.text('asistente_humano_escribir'.tr()), findsOneWidget);
    expect(find.text('asistente_ir_faq'.tr()), findsOneWidget);
  });

  testWidgets('a courier without FAQs still offers WhatsApp assistance',
      (tester) async {
    await GetIt.I.unregister<CourierService>();
    GetIt.I.registerSingleton<CourierService>(
      _AssistantCourierService(hasFaq: false),
    );
    await open(tester);

    await tester.tap(find.text('¿Tengo paquetes disponibles?'));
    await tester.pump();
    assistant.pending!.completeError(
      const AssistantQuotaException(
        scope: AssistantQuotaScope.sessionDaily,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('asistente_no_puedo_responder_ahora'.tr()),
      findsOneWidget,
    );
    expect(find.text('asistente_humano_escribir'.tr()), findsOneWidget);
    expect(find.text('asistente_ir_faq'.tr()), findsNothing);
  });

  testWidgets('a courier without the module has no assistant to deep-link into',
      (tester) async {
    await GetIt.I.unregister<CourierService>();
    GetIt.I.registerSingleton<CourierService>(
      _AssistantCourierService(assistant: false),
    );

    await open(tester);

    expect(find.text('asistente_no_disponible'.tr()), findsOneWidget);
    expect(find.text('Escribe tu pregunta'), findsNothing);
  });

  testWidgets('sends the customer back to sign in when the session ended',
      (tester) async {
    await open(tester);

    await tester.tap(find.text('¿Tengo paquetes disponibles?'));
    await tester.pump();
    assistant.pending!.completeError(const AssistantSignedOutException());
    await tester.pumpAndSettle();

    expect(
      find.text('Tu sesión terminó. Vuelve a entrar para seguir preguntando.'),
      findsOneWidget,
    );
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('survives 200% accessibility text', (tester) async {
    await open(tester, textScaler: const TextScaler.linear(2));

    await tester.enterText(
        find.byType(TextField), '¿Dónde están sus oficinas?');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    assistant.pending!.complete(const AssistantReply(text: _branchAnswer));
    await tester.pumpAndSettle();

    expect(find.textContaining('Av. Winston Churchill'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

/// An assistant whose answers the test hands over one at a time.
class _FakeAssistant extends AssistantService {
  _FakeAssistant();

  /// Which customer the next identity read belongs to.
  String account = 'BM-096791';

  @override
  Future<AssistantIdentity> identity() async => AssistantIdentity(
        empresaId: 'empresa',
        sessionId: 'session',
        firstName: 'Temístocles',
        lastName: 'Roa',
        userAccount: account,
        sucursalId: 'DO-BVT',
      );

  /// Answers queued for the next questions, used before [pending].
  final List<String> answers = [];

  Completer<AssistantReply>? pending;

  int askCount = 0;

  @override
  Future<AssistantReply> ask(String question) {
    askCount++;
    if (answers.isNotEmpty) {
      return Future.value(AssistantReply(text: answers.removeAt(0)));
    }
    pending = Completer<AssistantReply>();
    return pending!.future;
  }
}

class _AssistantCourierService extends CourierService {
  _AssistantCourierService({this.assistant = true, this.hasFaq = true}) {
    // This brand pays for the module; the screens under test are the ones it
    // unlocks.
    assistantEnabled.value = assistant;
  }

  /// Whether this courier bought the assistant module.
  final bool assistant;

  /// Whether this courier publishes a frequently asked questions module.
  final bool hasFaq;

  String assistantName = '';
  String avatarSvg = '';

  @override
  Future<Empresa> getEmpresa({
    bool ignoreCache = false,
    bool forceFirstTime = false,
    bool retryEmtpy = false,
  }) async =>
      Empresa.empty()
        ..hasPreguntas = hasFaq
        ..hasAssistantModule = assistant
        ..assistantSettings = jsonEncode({
          if (assistantName.isNotEmpty) 'Name': assistantName,
          if (avatarSvg.isNotEmpty) 'AvatarSvg': avatarSvg,
        });

  @override
  Future<UserProfile> getUserProfile() async => UserProfile(
        cuenta: 'BM-096791',
        nombre: 'Temístocles Roa',
        email: 'cliente@example.com',
        sucursal: 'DO-BVT',
        fotoPerfilUrl: '',
        direccionBuzon: '',
        buzones: const [],
        whatsappSucursal: '8095550100',
      );
}
