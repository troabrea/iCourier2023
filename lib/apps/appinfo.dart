import 'package:firebase_core/firebase_core.dart';

abstract class AppInfo {
  /// Stable slug used to load the local WhiteLabel configuration.
  String get brandSlug => metricsPrefixKey.toLowerCase();

  /// App Store storefront used to look up this WhiteLabel on iOS.
  String get appStoreCountryCode => 'DO';

  String get companyId;
  String get iphoneAnalyticsAppId;
  String get androidAnalyticsAppId;
  String get metricsPrefixKey;
  String get pushChannelTopic;
  String get centerIconImage;
  String get brandLogoImage;
  String get brandLogoImageDark;
  double get centerIconSize;
  double get centerInactiveIconSize;
  int get defaultTab;
  set defaultTab(int value);
  String get defaultLocale;
  set defaultLocale(String value);
  String get additionalLocale;
  set additionalLocale(String value);
  String get currencyCode;
  FirebaseOptions get appFirebaseOptions;
}
