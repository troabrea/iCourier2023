import 'package:flutter_test/flutter_test.dart';
import 'package:icourier/navigation/app_routes.dart';
import 'package:icourier/navigation/pending_destination_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AppDeepLinkParser', () {
    final parser = AppDeepLinkParser(urlScheme: 'bmcargo');

    test('acepta rutas internas y el deep link canónico de paquete', () {
      expect(parser.parse('/inicio'), AppRoutes.home);
      expect(
        parser.parse('bmcargo://paquete/ABC%20123'),
        '/paquete/ABC%20123',
      );
      expect(
        parser.parse('bmcargo:///paquete/ABC/factura'),
        '/paquete/ABC/factura',
      );
    });

    test('rechaza esquemas y rutas externas no permitidas', () {
      expect(parser.parse('https://example.com/paquete/123'), isNull);
      expect(parser.parse('otra://paquete/123'), isNull);
      expect(parser.parse('bmcargo://configuracion/secreta'), isNull);
      expect(parser.parse('bmcargo://user@example.com/paquete/123'), isNull);
    });

    test('clasifica destinos que requieren una sesión', () {
      expect(AppDeepLinkParser.isProtected('/paquete/123'), isTrue);
      expect(AppDeepLinkParser.isProtected(AppRoutes.messages), isTrue);
      expect(AppDeepLinkParser.isProtected(AppRoutes.news), isFalse);
    });
  });

  test('PendingDestinationStore restaura el destino una sola vez', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final store = SharedPreferencesPendingDestinationStore(preferences);

    await store.save('/paquete/123');

    expect(await store.take(), '/paquete/123');
    expect(await store.take(), isNull);
  });
}
