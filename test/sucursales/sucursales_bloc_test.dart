import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/apps/appinfo.dart';
import 'package:icourier/apps/bmcargo/appinfo_bmcargo.dart';
import 'package:icourier/services/courier_service.dart';
import 'package:icourier/services/model/login_model.dart';
import 'package:icourier/services/model/sucursal.dart';
import 'package:icourier/sucursales/bloc/sucursales_bloc.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<AppInfo>(BmcargoAppInfo());
  });

  tearDown(() => GetIt.I.reset());

  test('places the account branch first, then follows API order', () async {
    final service = _BranchService([
      _branch(name: 'Orden 20', code: 'O20', order: 20),
      _branch(name: 'Predeterminada', code: 'FAV', order: 40),
      _branch(name: 'Orden 30', code: 'O30', order: 30),
      _branch(name: 'Orden 10', code: 'O10', order: 10),
    ]);
    final bloc = SucursalesBloc(service);
    addTearDown(bloc.close);

    bloc.add(const LoadApiEvent());
    final state = await bloc.stream.firstWhere(
      (state) => state is SucursalesLoadedState,
    ) as SucursalesLoadedState;

    expect(
      state.sucursales.map((branch) => branch.nombre),
      ['Predeterminada', 'Orden 10', 'Orden 20', 'Orden 30'],
    );
    expect(state.sucursales.first.isFavorite, isTrue);
    expect(
      state.sucursales.first.orden,
      40,
      reason: 'La prioridad no debe sobrescribir el orden recibido del API.',
    );
  });
}

final class _BranchService extends CourierService {
  _BranchService(this.branches);

  final List<Sucursal> branches;

  @override
  Future<UserProfile> getUserProfile() async => UserProfile(
        cuenta: 'BM-001',
        nombre: 'Cliente',
        email: 'cliente@example.com',
        sucursal: 'FAV',
        fotoPerfilUrl: '',
        direccionBuzon: '',
        buzones: [],
      );

  @override
  Future<List<Sucursal>> getSucursales(
    bool ignoreCache, {
    bool trackEvent = true,
  }) async =>
      branches;
}

Sucursal _branch({
  required String name,
  required String code,
  required double order,
}) =>
    Sucursal(
      registroId: code,
      empresa: 'demo',
      nombre: name,
      codigo: code,
      direccion: 'Santo Domingo',
      ciudad: 'Santo Domingo',
      pais: 'República Dominicana',
      horario: '',
      telefonoOficina: '',
      telefonoVentas: '',
      email: '',
      imagenId: '',
      latitud: 18.4861,
      longitud: -69.9312,
      orden: order,
      deleted: false,
    );
