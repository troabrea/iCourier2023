import 'dart:convert';

import 'package:event/event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icourier/navigation/app_router.dart';
import 'package:icourier/navigation/app_routes.dart';
import 'package:icourier/navigation/router_session.dart';
import 'package:icourier/navigation/selected_tab_store.dart';
import 'package:icourier/services/app_events.dart';
import 'package:icourier/theme/brand_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/brand_test_app.dart';

void main() {
  const standardTabs = [
    TabModule.news,
    TabModule.branches,
    TabModule.home,
    TabModule.calculator,
    TabModule.more,
  ];

  test('restores the stable module after the app is loaded again', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final store = SelectedTabStore(preferences);

    await store.save(TabModule.calculator);

    expect(
      SelectedTabStore(preferences).restoreIndex(
        standardTabs,
        fallbackIndex: 2,
      ),
      3,
    );
  });

  test('survives a different tab order by storing the module identity',
      () async {
    SharedPreferences.setMockInitialValues({
      SelectedTabStore.storageKey: TabModule.services.name,
    });
    final preferences = await SharedPreferences.getInstance();
    final store = SelectedTabStore(preferences);
    const serviceFirstTabs = [
      TabModule.services,
      TabModule.branches,
      TabModule.home,
      TabModule.calculator,
      TabModule.more,
    ];

    expect(
      store.restoreIndex(serviceFirstTabs, fallbackIndex: 2),
      0,
    );
  });

  test('reads the index written by the previous navigation shell', () async {
    const contentKey = 'content123lastSelectedTab';
    SharedPreferences.setMockInitialValues({
      'lastSelectedTab': jsonEncode({
        'content': contentKey,
        'type': 'type123lastSelectedTab',
      }),
      contentKey: '3',
    });
    final preferences = await SharedPreferences.getInstance();

    expect(
      SelectedTabStore(preferences).restoreIndex(
        standardTabs,
        fallbackIndex: 2,
      ),
      3,
    );
  });

  test('falls back safely when persisted and configured values are invalid',
      () async {
    SharedPreferences.setMockInitialValues({
      SelectedTabStore.storageKey: 'removed-module',
      'lastSelectedTab': '99',
    });
    final preferences = await SharedPreferences.getInstance();

    expect(
      SelectedTabStore(preferences).restoreIndex(
        standardTabs,
        fallbackIndex: 99,
      ),
      2,
    );
  });

  test('router starts an active session in the restored tab', () async {
    SharedPreferences.setMockInitialValues({
      SelectedTabStore.storageKey: TabModule.calculator.name,
    });
    final preferences = await SharedPreferences.getInstance();
    final session = RouterSession(
      initiallyLoggedIn: true,
      loginChanges: Event<LoginChanged>(),
    );
    final router = AppRouter.create(
      config: loadTestBrand('bmcargo'),
      session: session,
      preferences: preferences,
      defaultTabIndex: 2,
    );
    addTearDown(() {
      router.dispose();
      session.dispose();
    });

    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutes.calculator,
    );
  });

  test('active account changes notify even while login remains active', () {
    final changes = Event<LoginChanged>();
    final session = RouterSession(
      initiallyLoggedIn: true,
      loginChanges: changes,
    );
    addTearDown(session.dispose);
    var notifications = 0;
    session.addListener(() => notifications++);

    changes.broadcast(LoginChanged(true, 'BM-002', 'Bruno'));

    expect(session.isLoggedIn, isTrue);
    expect(notifications, 1);
  });
}
