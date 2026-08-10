import 'package:firebase_core/firebase_core.dart';
import 'package:icourier/apps/blumbox/firebase_options_blumbox.dart';

import '../appinfo.dart';

class BlumBoxAppInfo extends AppInfo {
  @override
  // TODO: implement appFirebaseOptions
  FirebaseOptions get appFirebaseOptions =>
      BlumboxDefaultFirebaseOptions.currentPlatform;
  @override
  String defaultLocale = 'es';
  @override
  String additionalLocale = '';

  @override
  String currencyCode = 'RD\$';

  @override
  int defaultTab = 2;

  @override
  String get brandLogoImage => "images/blumbox/brand_logo.png";

  @override
  String get brandLogoImageDark => "images/blumbox/brand_logo.png";

  @override
  String get centerIconImage => "images/blumbox/icon.png";

  @override
  String get androidAnalyticsAppId => "4d6a4db6-ae2b-4f75-a55f-d1a5c7a8deca";

  @override
  String get iphoneAnalyticsAppId => "295afe41-6b08-4f2b-accd-ce64ec743458";

  @override
  String get companyId => "d836492e-517e-490c-9615-3c2b65bf7755";

  @override
  String get metricsPrefixKey => "BLUMBOX";

  @override
  String get pushChannelTopic => "BLUMBOX";

  @override
  double get centerIconSize => 60;
  @override
  double get centerInactiveIconSize => 30;
}
