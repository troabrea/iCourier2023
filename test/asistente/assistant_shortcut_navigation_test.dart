import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:icourier/asistente/asistente.dart';
import 'package:icourier/navigation/app_routes.dart';
import 'package:icourier/theme/brand_config.dart';

import '../helpers/brand_test_app.dart';

/// Rebuilds the shape of the real tree that produced the crash: the tabs live
/// inside a `StatefulShellRoute`, and the assistant is a top-level route pushed
/// over it. Pushing a location that belongs to a shell branch stacks the shell
/// on itself and the navigator raises duplicate page keys — verified by hand
/// against this harness before the guard went in, and not kept as a test
/// because the framework assertion fails the run before an expectation can
/// catch it.
GoRouter _router({required String tapRoute}) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => Scaffold(body: shell),
        branches: [
          for (final location in const [AppRoutes.home, AppRoutes.branches])
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: location,
                  pageBuilder: (context, state) => NoTransitionPage(
                    child: Scaffold(
                      body: Center(
                        child: TextButton(
                          onPressed: () => context.push(AppRoutes.assistant),
                          child: Text('abrir $location'),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      GoRoute(
        path: AppRoutes.assistant,
        builder: (context, state) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => openAssistantShortcut(context, tapRoute),
              child: const Text('Ver sucursales'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.receptions,
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('recepciones'))),
      ),
    ],
  );
}

Future<void> _openAssistant(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      locale: const Locale('es'),
      theme: ThemeData.light(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('abrir ${AppRoutes.home}'));
  await tester.pumpAndSettle();
  expect(find.text('Ver sucursales'), findsOneWidget);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<BrandConfig>(loadTestBrand('bmcargo'));
  });

  tearDown(() => GetIt.I.reset());

  testWidgets('a tab destination switches branches instead of crashing',
      (tester) async {
    await _openAssistant(
      tester,
      _router(tapRoute: AppRoutes.branches),
    );

    await tester.tap(find.text('Ver sucursales'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // The customer asked to be taken there, so the conversation closes behind
    // them rather than lurking under the branch list.
    expect(find.text('abrir ${AppRoutes.branches}'), findsOneWidget);
    expect(find.text('Ver sucursales'), findsNothing);
  });

  testWidgets('a stacked destination still pushes, so back returns to the answer',
      (tester) async {
    await _openAssistant(
      tester,
      _router(tapRoute: AppRoutes.receptions),
    );

    await tester.tap(find.text('Ver sucursales'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('recepciones'), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator).last).pop();
    await tester.pumpAndSettle();

    expect(find.text('Ver sucursales'), findsOneWidget);
  });

  test('the brand knows which locations are its tab roots', () {
    final navigation = GetIt.I<BrandConfig>().navigation;

    for (final module in navigation.tabs) {
      expect(navigation.isTabRoot(module.location), isTrue);
    }
    expect(navigation.isTabRoot(AppRoutes.receptions), isFalse);
    expect(navigation.isTabRoot(AppRoutes.assistant), isFalse);
  });
}
