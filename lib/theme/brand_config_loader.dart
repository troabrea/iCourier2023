import 'dart:convert';

import 'package:flutter/services.dart';

import 'brand_config.dart';
import 'brand_config_validator.dart';

/// Loads the active brand from the application bundle.
abstract final class BrandConfigLoader {
  static Future<BrandConfig> load(String slug) async {
    final normalized = slug.toLowerCase();
    final jsonText = await rootBundle.loadString('whitelabel/$normalized.json');
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Invalid WhiteLabel config for $normalized');
    }
    BrandConfigValidator.validate(decoded, expectedSlug: normalized);
    final config = BrandConfig.fromJson(decoded);
    if (config.schema != 1 || config.slug != normalized) {
      throw FormatException('Unexpected WhiteLabel config for $normalized');
    }
    return config;
  }
}
