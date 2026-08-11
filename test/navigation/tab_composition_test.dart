import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:icourier/theme/brand_config.dart';

/// Which modules occupy a tab is whitelabel configuration, and the screens
/// compose themselves from it. These checks pin that contract so a brand
/// variance never becomes a conditional in the UI.
void main() {
  List<BrandConfig> loadAll() => Directory('whitelabel')
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.json'))
      .where((file) => !file.path.endsWith('_schema.json'))
      .map(
        (file) => BrandConfig.fromJson(
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
        ),
      )
      .toList(growable: false);

  group('composición de tabs', () {
    test('las 35 marcas declaran cinco tabs con home al centro', () {
      final configs = loadAll();
      expect(configs.length, 35);
      for (final config in configs) {
        expect(config.navigation.tabs.length, 5, reason: config.slug);
        expect(config.navigation.tabs[2], TabModule.home, reason: config.slug);
      }
    });

    test('bmcargo pone servicios en un tab y deja noticias fuera', () {
      final bmcargo =
          loadAll().firstWhere((config) => config.slug == 'bmcargo');
      expect(bmcargo.navigation.tabs, contains(TabModule.services));
      expect(bmcargo.navigation.tabs, isNot(contains(TabModule.news)));
    });

    test('toda marca deja al menos un módulo de contenido fuera del tab', () {
      // El módulo excluido es el que se alcanza desde "más" con botón de
      // retorno; si no hubiera ninguno, esa pantalla quedaría inalcanzable.
      for (final config in loadAll()) {
        final tabs = config.navigation.tabs.toSet();
        final stacked = TabModule.values.where((m) => !tabs.contains(m));
        expect(stacked, isNotEmpty, reason: config.slug);
      }
    });

    test('ningún módulo aparece dos veces en la barra', () {
      for (final config in loadAll()) {
        expect(
          config.navigation.tabs.toSet().length,
          config.navigation.tabs.length,
          reason: config.slug,
        );
      }
    });
  });
}
