import 'package:flutter/material.dart';

import '../services/model/empresa.dart';

/// Modules that can occupy a persistent navigation slot.
enum TabModule { news, branches, home, calculator, more, services }

/// Color values used to build one brightness of a brand theme.
@immutable
final class BrandPalette {
  const BrandPalette({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.text,
    required this.textMuted,
    required this.border,
    required this.success,
    required this.warning,
    required this.danger,
  });

  factory BrandPalette.fromJson(
    Map<String, dynamic> json, {
    required BrandPalette defaults,
  }) {
    Color read(String key, Color fallback) {
      final value = json[key];
      return value is String ? _parseColor(value, fallback) : fallback;
    }

    final primary = read('primary', defaults.primary);
    final secondary = read('secondary', defaults.secondary);

    return BrandPalette(
      bg: read('bg', defaults.bg),
      surface: read('surface', defaults.surface),
      surfaceAlt: read('surfaceAlt', defaults.surfaceAlt),
      primary: primary,
      onPrimary: _accessibleForeground(
        primary,
        read('onPrimary', defaults.onPrimary),
      ),
      secondary: secondary,
      onSecondary: _accessibleForeground(
        secondary,
        read('onSecondary', defaults.onSecondary),
      ),
      text: read('text', defaults.text),
      textMuted: read('textMuted', defaults.textMuted),
      border: read('border', defaults.border),
      success: read('success', defaults.success),
      warning: read('warning', defaults.warning),
      danger: read('danger', defaults.danger),
    );
  }

  static const lightDefaults = BrandPalette(
    bg: Color(0xfff7f7f5),
    surface: Color(0xffffffff),
    surfaceAlt: Color(0xffeeeeea),
    primary: Color(0xff22577a),
    onPrimary: Color(0xffffffff),
    secondary: Color(0xff4f772d),
    onSecondary: Color(0xffffffff),
    text: Color(0xff1f2529),
    textMuted: Color(0xff687076),
    border: Color(0xffdfe2e3),
    success: Color(0xff2e7d4f),
    warning: Color(0xffb26a00),
    danger: Color(0xffb3261e),
  );

  static const darkDefaults = BrandPalette(
    bg: Color(0xff111416),
    surface: Color(0xff1b1f22),
    surfaceAlt: Color(0xff252a2e),
    primary: Color(0xff86c5ea),
    onPrimary: Color(0xff082331),
    secondary: Color(0xffa6cf7b),
    onSecondary: Color(0xff14250a),
    text: Color(0xfff0f2f3),
    textMuted: Color(0xffb3bbc0),
    border: Color(0xff3d4449),
    success: Color(0xff72c995),
    warning: Color(0xffffb95c),
    danger: Color(0xffff8a80),
  );

  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color text;
  final Color textMuted;
  final Color border;
  final Color success;
  final Color warning;
  final Color danger;
}

/// Corner radii supplied by a WhiteLabel configuration.
@immutable
final class BrandRadii {
  const BrandRadii({required this.sm, required this.md, required this.lg});

  factory BrandRadii.fromJson(Map<String, dynamic> json) => BrandRadii(
        sm: _readDouble(json['sm'], 8),
        md: _readDouble(json['md'], 16),
        lg: _readDouble(json['lg'], 24),
      );

  final double sm;
  final double md;
  final double lg;
}

/// Brand-controlled assets available before login and while offline.
@immutable
final class BrandAssets {
  const BrandAssets({required this.logoWide, required this.logoMark});

  factory BrandAssets.fromJson(Map<String, dynamic> json) => BrandAssets(
        logoWide: json['logoWide'] as String? ?? '',
        logoMark: json['logoMark'] as String? ?? '',
      );

  final String logoWide;
  final String logoMark;
}

/// Calculator presentation constraints that vary by local brand contract.
@immutable
final class BrandCalculatorConfig {
  const BrandCalculatorConfig({
    this.minimumWeight = 0.01,
    this.initialWeight = 1,
    this.showContactEmail = false,
  });

  factory BrandCalculatorConfig.fromJson(Map<String, dynamic> json) =>
      BrandCalculatorConfig(
        minimumWeight: _readDouble(json['minimumWeight'], 0.01),
        initialWeight: _readDouble(json['initialWeight'], 1),
        showContactEmail: json['showContactEmail'] as bool? ?? false,
      );

  final double minimumWeight;
  final double initialWeight;
  final bool showContactEmail;
}

/// Optional legacy password reset integration configured without brand checks.
@immutable
final class BrandPasswordResetConfig {
  const BrandPasswordResetConfig({
    this.urlTemplate = '',
    this.headerName = '',
    this.headerValue = '',
  });

  factory BrandPasswordResetConfig.fromJson(Map<String, dynamic> json) =>
      BrandPasswordResetConfig(
        urlTemplate: json['urlTemplate'] as String? ?? '',
        headerName: json['headerName'] as String? ?? '',
        headerValue: json['headerValue'] as String? ?? '',
      );

  final String urlTemplate;
  final String headerName;
  final String headerValue;

  bool get enabled => urlTemplate.contains('{email}');

  Map<String, String> get headers =>
      headerName.isEmpty ? const {} : {headerName: headerValue};
}

/// Backend value and localized presentation label for a pickup option.
@immutable
final class BrandPickupMode {
  const BrandPickupMode({required this.label, required this.value});

  factory BrandPickupMode.fromJson(Map<String, dynamic> json) =>
      BrandPickupMode(
        label: json['label'] as String? ?? '',
        value: json['value'] as String? ?? '',
      );

  final String label;
  final String value;
}

/// Capabilities requested by a brand before backend availability is applied.
@immutable
final class BrandCapabilities {
  const BrandCapabilities({
    this.delivery = false,
    this.payments = false,
    this.points = false,
    this.prealerts = true,
    this.widgets = false,
    this.notifications = true,
    this.pushTopicUsesSessionId = false,
    this.pickupModes = const [],
  });

  factory BrandCapabilities.fromJson(Map<String, dynamic> json) =>
      BrandCapabilities(
        delivery: json['delivery'] as bool? ?? false,
        payments: json['payments'] as bool? ?? false,
        points: json['points'] as bool? ?? false,
        prealerts: json['prealerts'] as bool? ?? true,
        widgets: json['widgets'] as bool? ?? false,
        notifications: json['notifications'] as bool? ?? true,
        pushTopicUsesSessionId:
            json['pushTopicUsesSessionId'] as bool? ?? false,
        pickupModes: (json['pickupModes'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(BrandPickupMode.fromJson)
            .where((mode) => mode.label.isNotEmpty && mode.value.isNotEmpty)
            .toList(growable: false),
      );

  final bool delivery;
  final bool payments;
  final bool points;
  final bool prealerts;
  final bool widgets;
  final bool notifications;
  final bool pushTopicUsesSessionId;
  final List<BrandPickupMode> pickupModes;

  /// Combines local entitlement with modules reported by the backend.
  BrandCapabilities resolve(Empresa? empresa) {
    if (empresa == null) {
      return this;
    }
    return BrandCapabilities(
      delivery: delivery && empresa.hasDelivery,
      payments: payments && empresa.hasPaymentsModule,
      points: points && empresa.hasPointsModule,
      prealerts: prealerts,
      widgets: widgets,
      notifications: notifications,
      pushTopicUsesSessionId: pushTopicUsesSessionId,
      pickupModes: pickupModes,
    );
  }
}

/// Defines the five persistent navigation positions for a brand.
@immutable
final class BrandNavigationConfig {
  BrandNavigationConfig({required List<TabModule> tabs})
      : tabs = List<TabModule>.unmodifiable(tabs) {
    if (tabs.length != 5 || tabs[2] != TabModule.home) {
      throw const FormatException(
        'navigation.tabs must contain five items with home at index 2',
      );
    }
  }

  factory BrandNavigationConfig.fromJson(Map<String, dynamic> json) {
    final rawTabs = json['tabs'];
    if (rawTabs is! List<dynamic>) {
      return BrandNavigationConfig.standard();
    }
    final tabs = rawTabs
        .whereType<String>()
        .map(
          (name) => TabModule.values.firstWhere(
            (value) => value.name == name,
            orElse: () => throw FormatException('Unknown tab module: $name'),
          ),
        )
        .toList(growable: false);
    return BrandNavigationConfig(tabs: tabs);
  }

  factory BrandNavigationConfig.standard() => BrandNavigationConfig(
        tabs: const [
          TabModule.news,
          TabModule.branches,
          TabModule.home,
          TabModule.calculator,
          TabModule.more,
        ],
      );

  final List<TabModule> tabs;
}

/// Complete local configuration for one WhiteLabel application.
@immutable
final class BrandConfig {
  const BrandConfig({
    required this.schema,
    required this.slug,
    required this.name,
    required this.tagline,
    required this.bundleId,
    required this.androidApplicationId,
    required this.urlScheme,
    required this.appGroup,
    required this.locale,
    required this.currency,
    required this.weightUnit,
    required this.headFont,
    required this.bodyFont,
    required this.radii,
    required this.light,
    required this.dark,
    required this.assets,
    required this.calculator,
    required this.passwordReset,
    required this.capabilities,
    required this.navigation,
    required this.loyaltyLabel,
  });

  factory BrandConfig.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> map(String key) =>
        (json[key] as Map<String, dynamic>?) ?? const <String, dynamic>{};

    final palettes = map('palettes');
    final fonts = map('fonts');
    return BrandConfig(
      schema: (json['schema'] as num?)?.toInt() ?? 1,
      slug: json['slug'] as String? ?? 'icourier',
      name: json['name'] as String? ?? 'iCourier',
      tagline: json['tagline'] as String? ?? '',
      bundleId: json['bundleId'] as String? ?? 'com.barolit.icourier',
      androidApplicationId: json['androidApplicationId'] as String? ??
          json['bundleId'] as String? ??
          'com.barolit.icourier',
      urlScheme: json['urlScheme'] as String? ?? 'icourier',
      appGroup: json['appGroup'] as String? ?? 'group.com.barolit.icourier',
      locale: json['locale'] as String? ?? 'es-DO',
      currency: json['currency'] as String? ?? 'RD\$',
      weightUnit: json['weightUnit'] as String? ?? 'lb',
      headFont: fonts['head'] as String? ?? 'Myriad',
      bodyFont: fonts['body'] as String? ?? 'Myriad',
      radii: BrandRadii.fromJson(map('radius')),
      light: BrandPalette.fromJson(
        (palettes['light'] as Map<String, dynamic>?) ?? const {},
        defaults: BrandPalette.lightDefaults,
      ),
      dark: BrandPalette.fromJson(
        (palettes['dark'] as Map<String, dynamic>?) ?? const {},
        defaults: BrandPalette.darkDefaults,
      ),
      assets: BrandAssets.fromJson(map('assets')),
      calculator: BrandCalculatorConfig.fromJson(map('calculator')),
      passwordReset: BrandPasswordResetConfig.fromJson(map('passwordReset')),
      capabilities: BrandCapabilities.fromJson(map('capabilities')),
      navigation: BrandNavigationConfig.fromJson(map('navigation')),
      loyaltyLabel: map('capabilities')['loyaltyLabel'] as String? ??
          'Puntos disponibles',
    );
  }

  final int schema;
  final String slug;
  final String name;
  final String tagline;
  final String bundleId;
  final String androidApplicationId;
  final String urlScheme;
  final String appGroup;
  final String locale;
  final String currency;
  final String weightUnit;
  final String headFont;
  final String bodyFont;
  final BrandRadii radii;
  final BrandPalette light;
  final BrandPalette dark;
  final BrandAssets assets;
  final BrandCalculatorConfig calculator;
  final BrandPasswordResetConfig passwordReset;
  final BrandCapabilities capabilities;
  final BrandNavigationConfig navigation;
  final String loyaltyLabel;
}

Color _parseColor(String value, Color fallback) {
  final normalized = value.replaceFirst('#', '');
  final withAlpha = normalized.length == 6 ? 'ff$normalized' : normalized;
  final parsed = int.tryParse(withAlpha, radix: 16);
  return parsed == null ? fallback : Color(parsed);
}

double _readDouble(Object? value, double fallback) =>
    value is num ? value.toDouble() : fallback;

Color _accessibleForeground(Color background, Color preferred) {
  if (_contrastRatio(background, preferred) >= 4.5) {
    return preferred;
  }
  const dark = Color(0xff101820);
  const light = Color(0xffffffff);
  return _contrastRatio(background, dark) >= _contrastRatio(background, light)
      ? dark
      : light;
}

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance() + 0.05;
  final secondLuminance = second.computeLuminance() + 0.05;
  return firstLuminance > secondLuminance
      ? firstLuminance / secondLuminance
      : secondLuminance / firstLuminance;
}
