import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/src/localization.dart';
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:icourier/theme/brand_config.dart';
import 'package:icourier/theme/brand_theme.dart';

BrandConfig loadTestBrand(String slug) {
  final json = jsonDecode(File('whitelabel/$slug.json').readAsStringSync());
  return BrandConfig.fromJson(json as Map<String, dynamic>);
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
