import 'package:firebase_core/firebase_core.dart';
import 'package:icourier/apps/brodpaq//firebase_options_brodpaq.dart';

import '../appinfo.dart';

class BrodpaqAppInfo extends AppInfo {
  @override
  FirebaseOptions appFirebaseOptions =
      BrodpaqDefaultFirebaseOptions.currentPlatform;

  @override
  String defaultLocale = 'es';
  @override
  String additionalLocale = '';

  @override
  String currencyCode = 'RD\$';

  @override
  int defaultTab = 2;

  @override
  String get brandLogoImage => "images/brodpaq/brand_logo.png";
  @override
  String get brandLogoImageDark => "images/brodpaq/brand_logo.png";
  @override
  String get centerIconImage => "images/brodpaq/icon.png";

  @override
  String get androidAnalyticsAppId => "BRODPAQ";

  @override
  String get iphoneAnalyticsAppId => "BRODPAQ";

  @override
  String get companyId => "f688adc8-ba6b-4588-ba7d-5a04c215d4db";

  @override
  String get metricsPrefixKey => "BRODPAQ";

  @override
  String get pushChannelTopic => "BRODPAQ";

  @override
  double get centerIconSize => 80;
  @override
  double get centerInactiveIconSize => 35;
}
