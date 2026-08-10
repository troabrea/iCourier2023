import 'brand_config.dart';

/// Strict validation for checked-in WhiteLabel JSON documents.
///
/// Runtime defaults remain in [BrandConfig]; this validator protects the 35
/// production documents from missing identity, navigation, or palette fields.
abstract final class BrandConfigValidator {
  /// Colours every document must declare; the rest are derived from `primary`.
  static const _requiredColors = [
    'primary',
    'onPrimary',
    'secondary',
    'onSecondary',
  ];

  /// Colours a brand may override once the derived family is not enough.
  static const _optionalColors = [
    'bg',
    'surface',
    'surfaceAlt',
    'text',
    'textMuted',
    'border',
    'success',
    'warning',
    'danger',
  ];

  static const _allColors = {..._requiredColors, ..._optionalColors};

  static final _hex = RegExp(r'^#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$');

  static void validate(
    Map<String, dynamic> json, {
    String? expectedSlug,
  }) {
    final schema = json['schema'];
    if (schema != 1) {
      throw const FormatException('schema must be 1');
    }
    final slug = _string(json, 'slug');
    if (!RegExp(r'^[a-z][a-z0-9]*$').hasMatch(slug)) {
      throw FormatException('Invalid slug: $slug');
    }
    if (expectedSlug != null && slug != expectedSlug) {
      throw FormatException('Expected $expectedSlug but found $slug');
    }
    _string(json, 'name');
    _identifier(json, 'bundleId');
    if (json['androidApplicationId'] != null) {
      _identifier(json, 'androidApplicationId');
    }
    final scheme = _string(json, 'urlScheme');
    if (!RegExp(r'^[a-z][a-z0-9+.-]*$').hasMatch(scheme)) {
      throw FormatException('Invalid urlScheme: $scheme');
    }
    _identifier(json, 'appGroup');
    _string(json, 'currency');
    _string(json, 'weightUnit');

    final fonts = _map(json, 'fonts');
    _string(fonts, 'head');
    _string(fonts, 'body');

    final radius = _map(json, 'radius');
    for (final key in ['sm', 'md', 'lg']) {
      final value = radius[key];
      if (value is! num || value <= 0) {
        throw FormatException('radius.$key must be positive');
      }
    }

    final assets = _map(json, 'assets');
    _string(assets, 'logoWide');
    _string(assets, 'logoMark');

    final palettes = _map(json, 'palettes');
    for (final brightness in ['light', 'dark']) {
      final palette = _map(palettes, brightness);
      for (final key in _requiredColors) {
        final color = _string(palette, key);
        if (!_hex.hasMatch(color)) {
          throw FormatException('palettes.$brightness.$key is not hex');
        }
      }
      // Optional colours still have to be hex when present: a malformed value
      // would otherwise fall back silently to a default and ship unnoticed.
      for (final key in _optionalColors) {
        final color = palette[key];
        if (color == null) {
          continue;
        }
        if (color is! String || !_hex.hasMatch(color)) {
          throw FormatException('palettes.$brightness.$key is not hex');
        }
      }
      final unknown = palette.keys
          .where((key) => !_allColors.contains(key))
          .toList(growable: false);
      if (unknown.isNotEmpty) {
        throw FormatException(
          'palettes.$brightness has unknown colours: ${unknown.join(', ')}',
        );
      }
    }

    _map(json, 'capabilities');
    final navigation = _map(json, 'navigation');
    final rawTabs = navigation['tabs'];
    if (rawTabs is! List<dynamic> || rawTabs.length != 5) {
      throw const FormatException('navigation.tabs must have five items');
    }
    final tabs = rawTabs.whereType<String>().toList(growable: false);
    if (tabs.length != 5 || tabs[2] != TabModule.home.name) {
      throw const FormatException('navigation.tabs requires home at index 2');
    }
    final allowed = TabModule.values.map((module) => module.name).toSet();
    if (!tabs.every(allowed.contains) || tabs.toSet().length != tabs.length) {
      throw const FormatException('navigation.tabs contains invalid modules');
    }
  }

  static Map<String, dynamic> _map(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! Map<String, dynamic>) {
      throw FormatException('$key must be an object');
    }
    return value;
  }

  static String _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('$key must be a non-empty string');
    }
    return value;
  }

  static void _identifier(Map<String, dynamic> json, String key) {
    final value = _string(json, key);
    if (!value.contains('.') || value.contains(' ')) {
      throw FormatException('$key is invalid');
    }
  }
}
