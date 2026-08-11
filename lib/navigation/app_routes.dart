import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Canonical route locations shared by navigation, notifications and widgets.
abstract final class AppRoutes {
  static const login = '/login';
  static const home = '/inicio';
  static const news = '/noticias';
  static const newsDetailPattern = '/noticias/:id';
  static const branches = '/sucursales';
  static const calculator = '/calculadora';
  static const more = '/mas';
  static const receptions = '/recepciones';
  static const available = '/disponibles';
  static const tracking = '/rastreo';
  static const idCard = '/carnet';
  static const messages = '/mensajes';
  static const prealert = '/prealerta';
  static const newPrealert = '/prealerta/nueva';
  static const services = '/servicios';
  static const accounts = '/mas/cuentas';
  static const history = '/mas/historico';
  static const invoices = '/mas/facturados';
  static const accountStatement = '/mas/estado-cuenta';
  static const faq = '/faq';
  static const onlinePayment = '/mas/pago-en-linea';
  static const packagePattern = '/paquete/:id';
  static const componentGallery = '/galeria-componentes';

  static String package(String id) => '/paquete/${Uri.encodeComponent(id)}';

  static String newsDetail(String id) => '/noticias/${Uri.encodeComponent(id)}';

  static String invoice(String id) => '${package(id)}/factura';
}

/// Back navigation that always has somewhere to go.
///
/// A screen reached by a deep link has nothing beneath it on the stack, so a
/// back action gated on `canPop` would render no button at all and strand the
/// user. Falling back to the home tab keeps every screen leavable.
extension AppBackNavigation on BuildContext {
  VoidCallback get popOrHome => () {
        if (canPop()) {
          pop();
          return;
        }
        go(AppRoutes.home);
      };
}

/// Strict parser for links allowed to enter the application.
final class AppDeepLinkParser {
  AppDeepLinkParser({required this.urlScheme});

  final String urlScheme;

  static final _staticRoutes = <String>{
    AppRoutes.login,
    AppRoutes.home,
    AppRoutes.news,
    AppRoutes.branches,
    AppRoutes.calculator,
    AppRoutes.more,
    AppRoutes.receptions,
    AppRoutes.available,
    AppRoutes.tracking,
    AppRoutes.idCard,
    AppRoutes.messages,
    AppRoutes.prealert,
    AppRoutes.newPrealert,
    AppRoutes.faq,
    AppRoutes.services,
  };

  static final _packageRoute = RegExp(r'^/paquete/[^/]+(?:/factura)?$');

  /// Returns an internal canonical location, or `null` for rejected links.
  String? parse(String rawLink) {
    final uri = Uri.tryParse(rawLink.trim());
    if (uri == null || uri.hasFragment || uri.userInfo.isNotEmpty) {
      return null;
    }

    late String path;
    if (uri.scheme.isEmpty) {
      path = uri.path;
    } else {
      if (uri.scheme.toLowerCase() != urlScheme.toLowerCase() || uri.hasPort) {
        return null;
      }
      path = uri.host.isEmpty ? uri.path : '/${uri.host}${uri.path}';
    }
    path = _normalizePath(path);
    if (!_isAllowed(path)) {
      return null;
    }
    return uri.hasQuery ? '$path?${uri.query}' : path;
  }

  static bool isProtected(String location) {
    final path = Uri.tryParse(location)?.path ?? '';
    return path != AppRoutes.login &&
        path != AppRoutes.news &&
        path != AppRoutes.branches &&
        path != AppRoutes.calculator &&
        path != AppRoutes.services;
  }

  static bool _isAllowed(String path) =>
      _staticRoutes.contains(path) || _packageRoute.hasMatch(path);

  static String _normalizePath(String value) {
    var path = value.startsWith('/') ? value : '/$value';
    path = path.replaceAll(RegExp(r'/+'), '/');
    if (path.length > 1 && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    return path;
  }
}
