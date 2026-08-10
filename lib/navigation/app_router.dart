import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../adicional/adicional.dart';
import '../adicional/appbrowser.dart';
import '../calculadora/calculadora.dart';
import '../courier/carnet_usuario.dart';
import '../courier/courier.dart';
import '../courier/courier_consulta_historica.dart';
import '../courier/courier_disponibles.dart';
import '../courier/courier_estado_cuenta.dart';
import '../courier/courier_facturados.dart';
import '../courier/courier_historia_paquete.dart';
import '../courier/factura_viewer.dart';
import '../courier/courier_prealertas_realizadas.dart';
import '../courier/courier_recepciones.dart';
import '../courier/crear_prealerta.dart';
import '../courier/crear_postalerta.dart';
import '../courier/cuentas_usuario.dart';
import '../courier/mensajes_usuario.dart';
import '../design_system/brand_states.dart';
import '../design_system/component_gallery.dart';
import '../design_system/core_components.dart';
import '../domain/package_stage.dart';
import '../noticas/noticias.dart';
import '../noticas/noticiadetalle.dart';
import '../preguntas/preguntas.dart';
import '../services/courier_service.dart';
import '../services/model/empresa.dart';
import '../services/model/login_model.dart';
import '../services/model/noticia.dart';
import '../services/model/recepcion.dart';
import '../servicios/servicios.dart';
import '../sucursales/sucursales.dart';
import '../theme/brand_config.dart';
import '../tracking/package_tracking_page.dart';
import 'app_routes.dart';
import 'brand_navigation_shell.dart';
import 'pending_destination_store.dart';
import 'router_session.dart';

abstract final class AppRouter {
  static GoRouter create({
    required BrandConfig config,
    required RouterSession session,
    required SharedPreferences preferences,
  }) {
    final pending = SharedPreferencesPendingDestinationStore(preferences);
    final tabModules = config.navigation.tabs.toSet();
    final routes = <RouteBase>[
      GoRoute(
        path: AppRoutes.newsDetailPattern,
        name: 'news-detail',
        builder: (context, state) {
          final news = state.extra;
          if (news is Noticia) {
            return NoticiaDetallePage(noticia: news);
          }
          return const Scaffold(
            body: BrandEmptyState(messageKey: 'no_resultados'),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const CourierPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => BrandNavigationShell(
          navigationShell: navigationShell,
          config: config,
        ),
        branches: config.navigation.tabs
            .map(
              (module) => StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: _path(module),
                    name: 'tab-${module.name}',
                    pageBuilder: (context, state) => NoTransitionPage(
                      child: _screen(module),
                    ),
                  ),
                ],
              ),
            )
            .toList(growable: false),
      ),
      ...TabModule.values.where((module) => !tabModules.contains(module)).map(
            (module) => GoRoute(
              path: _path(module),
              name: module.name,
              builder: (context, state) => _screen(module),
            ),
          ),
      if (kDebugMode)
        GoRoute(
          path: AppRoutes.componentGallery,
          name: 'component-gallery',
          builder: (context, state) => ComponentGallery(config: config),
        ),
      GoRoute(
        path: AppRoutes.receptions,
        name: 'receptions',
        builder: (context, state) => _AsyncRoute<List<Recepcion>>(
          load: () async {
            final receptions =
                await GetIt.I<CourierService>().getRecepciones(false);
            if (state.uri.queryParameters['retenido'] == 'true') {
              return receptions
                  .where((reception) => reception.retenido)
                  .toList(growable: false);
            }
            return receptions;
          },
          builder: (context, receptions) => RecepcionesPage(
            recepciones: receptions,
            titulo: state.uri.queryParameters['retenido'] == 'true'
                ? 'sin_factura'.tr()
                : 'recepciones'.tr(),
            initialStage: _stageFromName(
              state.uri.queryParameters['estado'],
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.packagePattern,
        name: 'package',
        builder: (context, state) => _PackageRoute(
          id: state.pathParameters['id']!,
          showInvoice: false,
        ),
        routes: [
          GoRoute(
            path: 'factura',
            name: 'package-invoice',
            builder: (context, state) => _PackageRoute(
              id: state.pathParameters['id']!,
              showInvoice: true,
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.available,
        name: 'available',
        builder: (context, state) =>
            _AsyncRoute<({Empresa empresa, List<Recepcion> packages})>(
          load: () async {
            final service = GetIt.I<CourierService>();
            final results = await Future.wait([
              service.getEmpresa(),
              service.getRecepciones(false),
            ]);
            final packages = (results[1] as List<Recepcion>)
                .where((reception) => reception.disponible)
                .toList(growable: false);
            return (empresa: results[0] as Empresa, packages: packages);
          },
          builder: (context, data) => DisponiblesPage(
            disponibles: data.packages,
            montoTotal: data.packages.fold(
              0,
              (total, reception) => total + reception.montoTotal(),
            ),
            empresa: data.empresa,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.tracking,
        name: 'tracking',
        // `<scheme>://rastreo?q=` preloads and runs the search.
        builder: (context, state) => PackageTrackingPage(
          initialQuery: state.uri.queryParameters['q'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.accounts,
        name: 'accounts',
        builder: (context, state) => _AsyncRoute<UserProfile>(
          load: GetIt.I<CourierService>().getUserProfile,
          builder: (context, profile) => Scaffold(
            appBar: ScreenHeader(title: 'sus_cuentas'.tr()),
            body: CuentasUsuario(userProfile: profile),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.history,
        name: 'history',
        builder: (context, state) => const ConsultaHistoricaPage(),
      ),
      GoRoute(
        path: AppRoutes.invoices,
        name: 'invoices',
        builder: (context, state) => _AsyncRoute<Empresa>(
          load: GetIt.I<CourierService>().getEmpresa,
          builder: (context, company) => FacturadosPage(empresa: company),
        ),
      ),
      GoRoute(
        path: AppRoutes.accountStatement,
        name: 'account-statement',
        builder: (context, state) => const EstadoDeCuenta(),
      ),
      GoRoute(
        path: AppRoutes.onlinePayment,
        name: 'online-payment',
        builder: (context, state) {
          final url = state.extra;
          if (url is! String || Uri.tryParse(url) == null) {
            return Scaffold(
              body: BrandErrorState(onRetry: context.pop),
            );
          }
          return AppBrowser(initialUrl: url, title: 'pago_en_linea'.tr());
        },
      ),
      GoRoute(
        path: AppRoutes.faq,
        name: 'faq',
        builder: (context, state) => const PreguntasPage(),
      ),
      GoRoute(
        path: AppRoutes.idCard,
        name: 'id-card',
        builder: (context, state) => _AsyncRoute<UserProfile>(
          load: GetIt.I<CourierService>().getUserProfile,
          builder: (context, profile) =>
              Scaffold(body: CarnetUsuario(userProfile: profile)),
        ),
      ),
      GoRoute(
        path: AppRoutes.messages,
        name: 'messages',
        builder: (context, state) => const MensajesUsuario(),
      ),
      GoRoute(
        path: AppRoutes.prealert,
        name: 'prealert',
        builder: (context, state) => const PrealertasRealizadas(),
        routes: [
          GoRoute(
            path: 'nueva',
            name: 'new-prealert',
            builder: (context, state) => const CrearPreAlertaPage(),
          ),
        ],
      ),
    ];

    return GoRouter(
      initialLocation: session.isLoggedIn ? AppRoutes.home : AppRoutes.login,
      routes: routes,
      refreshListenable: session,
      redirect: (context, state) {
        final location = state.uri.toString();
        if (!session.isLoggedIn && AppDeepLinkParser.isProtected(location)) {
          pending.save(location);
          return AppRoutes.login;
        }
        if (session.isLoggedIn && state.uri.path == AppRoutes.login) {
          final destination = preferences.getString(
            SharedPreferencesPendingDestinationStore.storageKey,
          );
          pending.clear();
          return destination ?? AppRoutes.home;
        }
        return null;
      },
    );
  }

  static String _path(TabModule module) => switch (module) {
        TabModule.news => AppRoutes.news,
        TabModule.branches => AppRoutes.branches,
        TabModule.home => AppRoutes.home,
        TabModule.calculator => AppRoutes.calculator,
        TabModule.more => AppRoutes.more,
        TabModule.services => AppRoutes.services,
      };

  static Widget _screen(TabModule module) => switch (module) {
        TabModule.news => const NoticiasPage(),
        TabModule.branches => const SucursalesPage(),
        TabModule.home => const CourierPage(),
        TabModule.calculator => const CalculadoraPage(),
        TabModule.more => const AdicionalInfoPage(),
        TabModule.services => const ServiciosPage(),
      };

  static PackageStage? _stageFromName(String? name) {
    for (final stage in PackageStage.values) {
      if (stage.name == name) return stage;
    }
    return null;
  }
}

class _PackageRoute extends StatelessWidget {
  const _PackageRoute({required this.id, required this.showInvoice});

  final String id;
  final bool showInvoice;

  @override
  Widget build(BuildContext context) {
    return _AsyncRoute<Recepcion?>(
      load: () async {
        final receptions =
            await GetIt.I<CourierService>().getRecepciones(false);
        return receptions.cast<Recepcion?>().firstWhere(
              (reception) =>
                  reception?.recepcionID == id ||
                  reception?.numeroRastreo == id,
              orElse: () => null,
            );
      },
      builder: (_, reception) {
        if (reception == null) {
          return const Scaffold(
            body: BrandEmptyState(messageKey: 'no_paquetes'),
          );
        }
        if (!showInvoice) {
          return HistoricoPaquetePage(recepcion: reception);
        }
        if (reception.fotoFacturaUrl.isEmpty) {
          return CrearPostAlertaPage(recepcion: reception);
        }
        return FacturaViewerPage(
          url: reception.fotoFacturaUrl,
          title: 'facturas_pendientes'.tr(),
        );
      },
    );
  }
}

class _AsyncRoute<T> extends StatefulWidget {
  const _AsyncRoute({required this.load, required this.builder});

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data) builder;

  @override
  State<_AsyncRoute<T>> createState() => _AsyncRouteState<T>();
}

class _AsyncRouteState<T> extends State<_AsyncRoute<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: BrandErrorState(
              onRetry: () => setState(() => _future = widget.load()),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(body: BrandSkeleton());
        }
        return widget.builder(context, snapshot.requireData);
      },
    );
  }
}
