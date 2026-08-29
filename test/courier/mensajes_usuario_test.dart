import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/apps/appinfo.dart';
import 'package:icourier/apps/bmcargo/appinfo_bmcargo.dart';
import 'package:icourier/courier/mensajes_usuario.dart';
import 'package:icourier/services/courier_service.dart';
import 'package:icourier/services/model/empresa.dart';
import 'package:icourier/services/model/mensaje.dart';
import 'package:icourier/surveys/survey_prompt_coordinator.dart';
import 'package:icourier/theme/brand_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/brand_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    initializeTestTranslations();
    await loadBrandFonts();
  });

  setUp(() async {
    await GetIt.I.reset();
    SharedPreferences.setMockInitialValues({});
    GetIt.I.registerSingleton<AppInfo>(BmcargoAppInfo());
    GetIt.I.registerSingleton<BrandConfig>(loadTestBrand('bmcargo'));
  });

  tearDown(() => GetIt.I.reset());

  testWidgets('keeps an active survey available after it was opened', (
    tester,
  ) async {
    const surveyUrl = 'https://example.com/encuesta/customer-satisfaction';
    SharedPreferences.setMockInitialValues({
      SharedPreferencesSurveyPromptStore.answeredUrlKey: surveyUrl,
    });
    GetIt.I.registerSingleton<CourierService>(
      _NotificationCenterService(
        company: _company(url: surveyUrl, activeUntil: '2999-12-31'),
      ),
    );
    SurveyInvitation? openedInvitation;

    await tester.pumpWidget(
      brandTestApp(
        config: GetIt.I<BrandConfig>(),
        child: MensajesUsuario(
          openSurvey: (invitation) async {
            openedInvitation = invitation;
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tu opinión nos ayuda'), findsOneWidget);
    expect(find.text('Abrir encuesta'), findsOneWidget);
    expect(find.text('No hay resultados'), findsNothing);

    await tester.tap(find.text('Abrir encuesta'));
    await tester.pump();

    expect(openedInvitation?.uri.toString(), surveyUrl);
    expect(find.text('Abrir encuesta'), findsOneWidget);
  });

  testWidgets('hides the manual action when the survey has expired', (
    tester,
  ) async {
    GetIt.I.registerSingleton<CourierService>(
      _NotificationCenterService(
        company: _company(
          url: 'https://example.com/encuesta/expired',
          activeUntil: '2000-01-01',
        ),
      ),
    );

    await tester.pumpWidget(
      brandTestApp(
        config: GetIt.I<BrandConfig>(),
        child: const MensajesUsuario(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Abrir encuesta'), findsNothing);
    expect(find.text('No hay resultados'), findsOneWidget);
  });

  testWidgets('lists a recent push message and marks it read when opened', (
    tester,
  ) async {
    final message = Mensaje(
      registroId: 'push-1',
      empresa: 'company',
      fecha: DateTime(2026, 8, 29),
      titulo: 'Paquete disponible',
      contenido: 'Ya puedes retirar tu paquete.',
      deleted: false,
      read: false,
    );
    final service = _NotificationCenterService(
      company: _company(url: '', activeUntil: ''),
      messages: [message],
    );
    GetIt.I.registerSingleton<CourierService>(service);

    await tester.pumpWidget(
      brandTestApp(
        config: GetIt.I<BrandConfig>(),
        child: const MensajesUsuario(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Paquete disponible'), findsOneWidget);
    expect(service.readMessageIds, isEmpty);

    await tester.tap(find.text('Paquete disponible'));
    await tester.pumpAndSettle();

    expect(find.text('Ya puedes retirar tu paquete.'), findsNWidgets(2));
    expect(service.readMessageIds, ['push-1']);
  });
}

final class _NotificationCenterService extends CourierService {
  _NotificationCenterService({
    required this.company,
    this.messages = const [],
  });

  final Empresa company;
  final List<Mensaje> messages;
  final List<String> readMessageIds = [];

  @override
  Future<Empresa> getEmpresa({
    bool ignoreCache = false,
    bool forceFirstTime = false,
    bool retryEmtpy = false,
  }) async =>
      company;

  @override
  Future<List<Mensaje>> getMensajes({bool ignoreCache = false}) async =>
      messages;

  @override
  Future<void> setMessagesRead(List<String> mensajesToMark) async {
    readMessageIds.addAll(mensajesToMark);
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
