import 'package:firebase_core/firebase_core.dart';
import 'package:icourier/apps/arribex/firebase_options_arribex.dart';

import '../appinfo.dart';

class ArribexAppInfo extends AppInfo {
  @override
  FirebaseOptions appFirebaseOptions =
      ArribexDefaultFirebaseOptions.currentPlatform;
  @override
  String defaultLocale = 'es';
  @override
  String additionalLocale = '';

  @override
  String currencyCode = 'RD\$';

  @override
  int defaultTab = 2;

  @override
  String get brandLogoImage => "images/arribex/brand_logo.png";
  @override
  String get brandLogoImageDark => "images/arribex/brand_logo.png";
  @override
  String get centerIconImage => "images/arribex/icon.png";

  @override
  String get androidAnalyticsAppId => "ARRIBEX";

  @override
  String get iphoneAnalyticsAppId => "ARRIBEX";

  @override
  String get companyId => "9efc3953-14c3-42ca-9da1-3f102dbdd832";

  @override
  String get metricsPrefixKey => "ARRIBEX";

  @override
  String get pushChannelTopic => "ARRIBEX";

  @override
  double get centerIconSize => 80;
  @override
  double get centerInactiveIconSize => 35;
}
