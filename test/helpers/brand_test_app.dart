import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/src/localization.dart';
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icourier/theme/brand_config.dart';
import 'package:icourier/theme/brand_theme.dart';

BrandConfig loadTestBrand(String slug) {
  final json = jsonDecode(File('whitelabel/$slug.json').readAsStringSync());
  return BrandConfig.fromJson(json as Map<String, dynamic>);
}

/// Registers the brand font families with the test binding.
///
/// Without this the golden harness falls back to Ahem and every string renders
/// as a filled box, which is exactly why the previous goldens passed while the
/// typography was wrong. Loading the real files makes a golden fail when the
/// family, size or weight of a label changes.
Future<void> loadBrandFonts({bool includeGoogleFamilies = false}) async {
  // Golden runs are offline and must be deterministic: a brand configured with
  // a Google family renders in the fallback here instead of reaching the
  // network. Production still resolves it through the package cache.
  GoogleFonts.config.allowRuntimeFetching = false;

  const families = <String, List<String>>{
    'Source Sans 3': [
      'fonts/SourceSans3-Regular.ttf',
      'fonts/SourceSans3-Medium.ttf',
      'fonts/SourceSans3-SemiBold.ttf',
      'fonts/SourceSans3-Bold.ttf',
    ],
    'Outfit': [
      'fonts/Outfit-Regular.ttf',
      'fonts/Outfit-Medium.ttf',
      'fonts/Outfit-SemiBold.ttf',
      'fonts/Outfit-Bold.ttf',
    ],
  };

  if (includeGoogleFamilies) {
    for (final family in ['Rubik', 'RedHatDisplay', 'RedHatText']) {
      final name = switch (family) {
        'RedHatDisplay' => 'Red Hat Display',
        'RedHatText' => 'Red Hat Text',
        _ => family,
      };
      final loader = FontLoader(name)
        ..addFont(Future.value(ByteData.sublistView(
          File('test/fonts/$family-Variable.ttf').readAsBytesSync(),
        )));
      await loader.load();
    }
  }

  for (final entry in families.entries) {
    final loader = FontLoader(entry.key);
    var loaded = false;
    for (final path in entry.value) {
      final file = File(path);
      if (!file.existsSync()) {
        continue;
      }
      loader.addFont(
        Future.value(ByteData.sublistView(file.readAsBytesSync())),
      );
      loaded = true;
    }
    if (loaded) {
      await loader.load();
    }
  }
}

void initializeTestTranslations() {
  final json = jsonDecode(File('translations/es.json').readAsStringSync());
  Localization.load(
    const Locale('es'),
    translations: Translations(json as Map<String, dynamic>),
  );
}

Widget brandTestApp({
  required BrandConfig config,
  required Widget child,
  Brightness brightness = Brightness.light,
  TextScaler textScaler = TextScaler.noScaling,
}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('es'),
      theme: BrandTheme.light(config),
      darkTheme: BrandTheme.dark(config),
      themeMode:
          brightness == Brightness.light ? ThemeMode.light : ThemeMode.dark,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SizedBox(width: 390, child: child),
          ),
        ),
      ),
    );
