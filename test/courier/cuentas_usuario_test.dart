import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/apps/appinfo.dart';
import 'package:icourier/apps/bmcargo/appinfo_bmcargo.dart';
import 'package:icourier/courier/cuentas_usuario.dart';
import 'package:icourier/services/courier_service.dart';
import 'package:icourier/services/model/login_model.dart';
import 'package:icourier/theme/brand_config.dart';

import '../helpers/brand_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    initializeTestTranslations();
    await loadBrandFonts();
  });

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<AppInfo>(BmcargoAppInfo());
    GetIt.I.registerSingleton<BrandConfig>(loadTestBrand('bmcargo'));
  });

  tearDown(() => GetIt.I.reset());

  testWidgets('oculta editar sin ProfileUrl ni EditProfileUrl', (
    tester,
  ) async {
    GetIt.I.registerSingleton<CourierService>(_AccountsService());

    await tester.pumpWidget(
      brandTestApp(
        config: GetIt.I<BrandConfig>(),
        child: CuentasUsuario(userProfile: _profile()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
  });

  testWidgets('ProfileUrl habilita editar solo para la cuenta activa', (
    tester,
  ) async {
    GetIt.I.registerSingleton<CourierService>(
      _AccountsService(profileOption: 'ProfileUrl'),
    );

    await tester.pumpWidget(
      brandTestApp(
        config: GetIt.I<BrandConfig>(),
        child: CuentasUsuario(userProfile: _profile()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
  });

  testWidgets('EditProfileUrl también habilita editar', (tester) async {
    GetIt.I.registerSingleton<CourierService>(
      _AccountsService(profileOption: 'EditProfileUrl'),
    );

    await tester.pumpWidget(
      brandTestApp(
        config: GetIt.I<BrandConfig>(),
        child: CuentasUsuario(userProfile: _profile()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
  });
}

UserProfile _profile() => UserProfile(
      cuenta: 'BM-096791',
      nombre: 'Temistocles Roa',
      email: 'temistocles@example.com',
      sucursal: 'SDQ',
      fotoPerfilUrl: '',
      direccionBuzon: '',
      buzones: [],
    );

final class _AccountsService extends CourierService {
  _AccountsService({this.profileOption = ''}) {
    optionsMap = <String, dynamic>{
      if (profileOption.isNotEmpty) profileOption: 'enabled',
    };
  }

  final String profileOption;

  @override
  Future<List<UserAccount>> getStoredAccounts() async => [
        UserAccount(
          sessionId: '',
          nombre: 'Temistocles Roa',
          userAccount: 'BM-096791',
          password: 'active-password',
        ),
        UserAccount(
          sessionId: '',
          nombre: 'Ada Lovelace',
          userAccount: 'BM-000002',
          password: 'inactive-password',
        ),
      ];

  @override
  Future<Map<String, String>> getProfileUrl() async => <String, String>{
        'UsuarioID': 'BM-096791',
        'UsuarioPW': 'secret',
      };

  @override
  Future<String> empresaOptionValue(String optionKey) async =>
      optionKey == profileOption ? 'enabled' : '';
}
