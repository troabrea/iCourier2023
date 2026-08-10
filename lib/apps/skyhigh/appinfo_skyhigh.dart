import 'package:firebase_core/firebase_core.dart';
import 'package:icourier/apps/skyhigh/firebase_options_skyhigh.dart';

import '../appinfo.dart';

class SkyHighAppInfo extends AppInfo {
  @override
  // TODO: implement appFirebaseOptions
  FirebaseOptions get appFirebaseOptions =>
      SkyHighDefaultFirebaseOptions.currentPlatform;
  @override
  String defaultLocale = 'es';
  @override
  String additionalLocale = '';
  @override
  String currencyCode = 'RD\$';

  @override
  int defaultTab = 2;

  @override
  String get brandLogoImage => "images/skyhigh/brand_logo.png";

  @override
  String get brandLogoImageDark => "images/skyhigh/brand_logo.png";

  @override
  String get centerIconImage => "images/skyhigh/icon.png";

  @override
  String get androidAnalyticsAppId => "209ffc11-ddcb-4044-82ff-a9d317f64f61";

  @override
  String get iphoneAnalyticsAppId => "17c72bdd-9d28-487d-990b-c3e00f3278a3";

  @override
  String get companyId => "046c2cee-69f6-41d3-ba77-60d817c6ea94";

  @override
  String get metricsPrefixKey => "SKYHIGH";

  @override
  String get pushChannelTopic => "SKYHIGH";

  @override
  double get centerIconSize => 60;
  @override
  double get centerInactiveIconSize => 40;
}
