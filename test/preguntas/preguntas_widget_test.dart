import 'dart:async';

import 'package:event/event.dart' as event;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/apps/appinfo.dart';
import 'package:icourier/apps/bmcargo/appinfo_bmcargo.dart';
import 'package:icourier/preguntas/preguntas.dart';
import 'package:icourier/services/app_events.dart';
import 'package:icourier/services/courier_service.dart';
import 'package:icourier/services/model/pregunta.dart';
import 'package:icourier/theme/brand_config.dart';

import '../helpers/brand_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _QuestionsService service;

  setUpAll(() async {
    initializeTestTranslations();
    await loadBrandFonts();
  });

  setUp(() async {
    await GetIt.I.reset();
    final config = loadTestBrand('bmcargo');
    GetIt.I.registerSingleton<AppInfo>(BmcargoAppInfo());
    GetIt.I.registerSingleton<BrandConfig>(config);
    GetIt.I.registerSingleton<event.Event<LoginChanged>>(
      event.Event<LoginChanged>(),
    );
    service = _QuestionsService();
    GetIt.I.registerSingleton<CourierService>(service);
  });

  tearDown(() => GetIt.I.reset());

  testWidgets('questions are inviting, searchable, and expandable',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      brandTestApp(
        config: GetIt.I<BrandConfig>(),
        child: const PreguntasPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Toca una pregunta para descubrir la respuesta.'),
        findsOneWidget);
    expect(find.text('2 preguntas para explorar'), findsOneWidget);
    expect(
        find.text('Regístrate desde la pantalla de acceso.'), findsOneWidget);
    expect(find.text('Consulta la dirección de tu sucursal.'), findsNothing);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(PreguntasPage),
      matchesGoldenFile('goldens/preguntas_lista.png'),
    );

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'dirección');
    await tester.pump();

    expect(find.text('¿Cómo creo mi cuenta?'), findsNothing);
    expect(find.text('¿Dónde retiro mis paquetes?'), findsOneWidget);
    expect(find.text('1 pregunta para explorar'), findsOneWidget);

    await tester.tap(find.text('¿Dónde retiro mis paquetes?'));
    await tester.pumpAndSettle();

    expect(find.text('Consulta la dirección de tu sucursal.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pull-to-refresh keeps the answers visible', (tester) async {
    await tester.pumpWidget(
      brandTestApp(
        config: GetIt.I<BrandConfig>(),
        child: const PreguntasPage(),
      ),
    );
    await tester.pumpAndSettle();

    service.refresh = Completer<List<Pregunta>>();
    final refresh = tester
        .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
        .show();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('¿Cómo creo mi cuenta?'), findsOneWidget);

    service.refresh!.complete(service.items);
    await tester.pumpAndSettle();
    await refresh;

    expect(service.requests, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('questions tolerate 200% accessibility text', (tester) async {
    await tester.pumpWidget(
      brandTestApp(
        config: GetIt.I<BrandConfig>(),
        textScaler: const TextScaler.linear(2),
        child: const PreguntasPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('¿Cómo creo mi cuenta?'), findsOneWidget);
    expect(
        find.text('Regístrate desde la pantalla de acceso.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _QuestionsService extends CourierService {
  int requests = 0;
  Completer<List<Pregunta>>? refresh;
  final List<Pregunta> items = [
    Pregunta(
      registroId: 'question-1',
      empresa: 'demo',
      titulo: '¿Cómo creo mi cuenta?',
      resumen: 'Regístrate desde la pantalla de acceso.',
      url: '',
      orden: 1,
      deleted: false,
    ),
    Pregunta(
      registroId: 'question-2',
      empresa: 'demo',
      titulo: '¿Dónde retiro mis paquetes?',
      resumen: 'Consulta la dirección de tu sucursal.',
      url: '',
      orden: 2,
      deleted: false,
    ),
  ];

  @override
  Future<List<Pregunta>> getPreguntas(bool ignoreCache) {
    requests++;
    if (ignoreCache && refresh != null) {
      return refresh!.future;
    }
    return Future.value(items);
  }
}
