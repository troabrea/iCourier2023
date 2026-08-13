import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icourier/theme/brand_config.dart';
import 'package:icourier/theme/brand_config_validator.dart';
import 'package:icourier/theme/brand_theme.dart';
import 'package:icourier/theme/brand_tokens.dart';

void main() {
  // Building a theme resolves the brand family; keep that offline and
  // deterministic here as well.
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('BrandConfig', () {
    test('aplica defaults compatibles a campos futuros ausentes', () {
      final config = BrandConfig.fromJson(const {});

      expect(config.schema, 1);
      expect(config.currency, r'RD$');
      expect(config.capabilities.prealerts, isTrue);
      expect(config.capabilities.delivery, isFalse);
      expect(config.calculator.showContactEmail, isFalse);
      expect(config.capabilities.pushTopicUsesSessionId, isFalse);
      expect(config.capabilities.pickupModes, isEmpty);
      expect(config.passwordReset.enabled, isFalse);
      expect(config.androidApplicationId, config.bundleId);
      expect(config.navigation.tabs, hasLength(5));
      expect(config.navigation.tabs[2], TabModule.home);
    });

    test('valida y renderiza las 35 marcas con contraste AA', () async {
      final files = Directory('whitelabel')
          .listSync()
          .whereType<File>()
          .where((file) => !file.path.endsWith('_schema.json'))
          .where((file) => file.path.endsWith('.json'))
          .toList();

      expect(files, hasLength(35));
      final contrastFailures = <String>[];
      for (final file in files) {
        final json =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        final config = BrandConfig.fromJson(json);
        BrandConfigValidator.validate(json, expectedSlug: config.slug);

        expect(config.slug, isNotEmpty, reason: file.path);
        expect(config.navigation.tabs, hasLength(5), reason: file.path);
        expect(File(config.assets.logoWide).existsSync(), isTrue,
            reason: '${file.path}: logoWide');
        expect(File(config.assets.logoMark).existsSync(), isTrue,
            reason: '${file.path}: logoMark');
        _checkAa(contrastFailures, config.light.primary, config.light.onPrimary,
            '${file.path}: light.primary');
        _checkAa(contrastFailures, config.light.text, config.light.bg,
            '${file.path}: light.text');
        _checkAa(contrastFailures, config.light.text, config.light.surface,
            '${file.path}: light.textOnSurface');
        _checkAa(contrastFailures, config.dark.primary, config.dark.onPrimary,
            '${file.path}: dark.primary');
        _checkAa(contrastFailures, config.dark.text, config.dark.bg,
            '${file.path}: dark.text');
        _checkAa(contrastFailures, config.dark.text, config.dark.surface,
            '${file.path}: dark.textOnSurface');

        final light = BrandTheme.light(config);
        final dark = BrandTheme.dark(config);
        final lightTokens = light.extension<BrandTokens>();
        final darkTokens = dark.extension<BrandTokens>();
        expect(lightTokens, isNotNull, reason: file.path);
        expect(darkTokens, isNotNull, reason: file.path);

        for (final entry in {
          'light': lightTokens!,
          'dark': darkTokens!,
        }.entries) {
          final tokens = entry.value;
          for (final accent in {
            'primary': tokens.primary,
            'success': tokens.success,
            'warning': tokens.warning,
            'danger': tokens.danger,
          }.entries) {
            final glyphColors = tokens.softAccentPair(accent.value);
            _checkMinimumContrast(
              contrastFailures,
              glyphColors.foreground,
              glyphColors.background,
              '${file.path}: ${entry.key}.${accent.key}SoftGlyph',
              3,
            );

            final labelColors = tokens.softAccentPair(
              accent.value,
              opacity: 0.14,
              minimumContrast: 4.5,
            );
            _checkAa(
              contrastFailures,
              labelColors.foreground,
              labelColors.background,
              '${file.path}: ${entry.key}.${accent.key}SoftLabel',
            );
          }

          final redeemBackground = Color.lerp(
            tokens.surface,
            tokens.secondary,
            0.22,
          )!;
          final redeemForeground = tokens.accessibleForeground(
            redeemBackground,
            preferred: tokens.primary,
          );
          _checkAa(
            contrastFailures,
            redeemForeground,
            redeemBackground,
            '${file.path}: ${entry.key}.redeemAction',
          );
        }
      }
      expect(contrastFailures, isEmpty);
    });

    test('preserva variantes por configuración sin condiciones de marca', () {
      final bmcargo = _config('bmcargo');
      final fixocargo = _config('fixocargo');
      final picknSend = _config('picknsend');
      final tls = _config('tls');
      final caribepack = _config('caribepack');

      expect(bmcargo.navigation.tabs.first, TabModule.services);
      expect(bmcargo.capabilities.pickupModes, hasLength(2));
      expect(fixocargo.capabilities.pickupModes, isEmpty);
      expect(picknSend.calculator.showContactEmail, isTrue);
      expect(tls.capabilities.pushTopicUsesSessionId, isTrue);
      expect(tls.passwordReset.enabled, isTrue);
      expect(caribepack.navigation.tabs[3], TabModule.services);
      expect(
        caribepack.androidApplicationId,
        'com.barolit.caribepackapp',
      );
    });

    test('la matriz nativa y los entrypoints cubren las 35 marcas', () {
      final configs = Directory('whitelabel')
          .listSync()
          .whereType<File>()
          .where((file) =>
              file.path.endsWith('.json') &&
              !file.path.endsWith('_schema.json'))
          .map((file) {
        final json = jsonDecode(file.readAsStringSync());
        return BrandConfig.fromJson(json as Map<String, dynamic>);
      }).toList(growable: false);
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();
      final xcode =
          File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();

      for (final config in configs) {
        final flavorBlock = RegExp(
          'create\\("${RegExp.escape(config.slug)}"\\)\\s*\\{([\\s\\S]*?)\\n\\s*\\}',
        ).firstMatch(gradle);
        expect(flavorBlock, isNotNull,
            reason: '${config.slug}: Android flavor');
        expect(
          flavorBlock!.group(1),
          contains('applicationId = "${config.androidApplicationId}"'),
          reason: '${config.slug}: Android applicationId',
        );

        final scheme = File(
          'ios/Runner.xcodeproj/xcshareddata/xcschemes/'
          '${config.slug}.xcscheme',
        );
        expect(scheme.existsSync(), isTrue, reason: '${config.slug}: scheme');
        expect(xcode, contains('name = "Debug-${config.slug}";'));
        expect(xcode, contains('name = "Profile-${config.slug}";'));
        expect(xcode, contains('name = "Release-${config.slug}";'));
        expect(
            xcode, contains('PRODUCT_BUNDLE_IDENTIFIER = ${config.bundleId};'));
        expect(xcode, contains('URL_SCHEME = ${config.urlScheme};'));
        expect(xcode, contains('APP_GROUP_ID = ${config.appGroup};'));

        final entrypointSlug = config.slug == 'picknsend' ? 'pns' : config.slug;
        final entrypoints = Directory('lib/apps')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('main_$entrypointSlug.dart'));
        expect(entrypoints, hasLength(1), reason: '${config.slug}: entrypoint');
      }
    });
  });
}

BrandConfig _config(String slug) {
  final json = jsonDecode(File('whitelabel/$slug.json').readAsStringSync());
  return BrandConfig.fromJson(json as Map<String, dynamic>);
}

void _checkAa(
  List<String> failures,
  Color foreground,
  Color background,
  String reason,
) =>
    _checkMinimumContrast(failures, foreground, background, reason, 4.5);

void _checkMinimumContrast(
  List<String> failures,
  Color foreground,
  Color background,
  String reason,
  double minimum,
) {
  final lighter = foreground.computeLuminance() + 0.05;
  final darker = background.computeLuminance() + 0.05;
  final ratio = lighter > darker ? lighter / darker : darker / lighter;
  if (ratio < minimum) {
    failures.add('$reason (${ratio.toStringAsFixed(2)}:1)');
  }
}
