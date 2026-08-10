import 'package:firebase_core/firebase_core.dart';

import '../appinfo.dart';

class SwoopAppInfo extends AppInfo {
  @override
  // TODO: implement appFirebaseOptions
  FirebaseOptions get appFirebaseOptions => throw UnimplementedError();
  @override
  String defaultLocale = 'en';
  @override
  String additionalLocale = '';
  @override
  String currencyCode = 'US\$';

  @override
  int defaultTab = 2;

  @override
  String get brandLogoImage => "images/swoop/brand_logo.png";

  @override
  String get brandLogoImageDark => "images/swoop/brand_logo.png";

  @override
  String get centerIconImage => "images/swoop/icon.png";

  @override
  String get androidAnalyticsAppId => "d2d37af7-4736-4d1a-8f2f-abd3be6eecdf";

  @override
  String get iphoneAnalyticsAppId => "36e90cab-3ece-4916-a079-7d7304a6f86e";

  @override
  String get companyId => "dc86e048-788d-479d-bf0f-87b4d0a44184";

  @override
  String get metricsPrefixKey => "SWOOP";

  @override
  String get pushChannelTopic => "SWOOP";

  @override
  double get centerIconSize => 60;
  @override
  double get centerInactiveIconSize => 40;
}
