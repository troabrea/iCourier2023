import 'package:flutter_test/flutter_test.dart';
import 'package:icourier/navigation/app_routes.dart';
import 'package:icourier/navigation/pending_destination_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  _deepLinkEntryContract();

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
      expect(AppDeepLinkParser.isProtected('/noticias/news-42'), isFalse);
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

void _deepLinkEntryContract() {
  // The router hands every incoming location with a scheme to the parser, so
  // these are the exact strings the platform delivers for an external link.
  final parser = AppDeepLinkParser(urlScheme: 'bmcargo');

  group('entrada de deep links externos', () {
    test('el destino canónico de paquete se traduce a una ruta interna', () {
      expect(parser.parse('bmcargo://paquete/KR0100458321'),
          '/paquete/KR0100458321');
    });

    test('conserva la query de las rutas que la usan', () {
      expect(parser.parse('bmcargo://rastreo?q=KR01'), '/rastreo?q=KR01');
      expect(parser.parse('bmcargo://recepciones?estado=disponible'),
          '/recepciones?estado=disponible');
    });

    test('un id inexistente sigue siendo una ruta válida', () {
      // Resolverlo es tarea de la pantalla, que muestra su estado vacío con
      // header; el router no debe caer en su página de error.
      expect(parser.parse('bmcargo://paquete/NOEXISTE123'),
          '/paquete/NOEXISTE123');
    });

    test('un esquema ajeno se rechaza', () {
      expect(parser.parse('otramarca://paquete/KR01'), isNull);
    });
  });
}
