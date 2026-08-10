import 'package:firebase_core/firebase_core.dart';
import 'package:icourier/apps/cps/firebase_options_cps.dart';

import '../appinfo.dart';

class CpsAppInfo extends AppInfo {
  @override
  // TODO: implement appFirebaseOptions
  FirebaseOptions get appFirebaseOptions =>
      CpsDefaultFirebaseOptions.currentPlatform;

  @override
  String defaultLocale = 'es';

  @override
  String currencyCode = 'RD\$';
  @override
  String additionalLocale = '';
  @override
  int defaultTab = 2;

  @override
  String get brandLogoImage => "images/cps/brand_logo.png";

  @override
  String get brandLogoImageDark => "images/cps/brand_logo_dark.png";

  @override
  String get centerIconImage => "images/cps/ic_launcher_foreground.png";

  @override
  String get androidAnalyticsAppId => "e6eb3042-6bcc-4531-b9e6-ba04613f18af";

  @override
  String get iphoneAnalyticsAppId => "06698ddf-3623-4243-b505-ca3e429c88dc";

  @override
  String get companyId => "894381da-10f7-45b8-b638-c8ede5835ce0";

  @override
  String get metricsPrefixKey => "CPS";

  @override
  String get pushChannelTopic => "CPS";

  @override
  double get centerIconSize => 120;
  @override
  double get centerInactiveIconSize => 60;
}
