import 'package:firebase_core/firebase_core.dart';
import 'package:icourier/apps/pns/firebase_options_picknsend.dart';

import '../appinfo.dart';

class PnsAppInfo extends AppInfo {
  @override
  // TODO: implement appFirebaseOptions
  FirebaseOptions get appFirebaseOptions =>
      PnsDefaultFirebaseOptions.currentPlatform;
  @override
  String defaultLocale = 'es';
  @override
  String additionalLocale = '';
  @override
  int defaultTab = 2;

  @override
  String currencyCode = 'RD\$';

  @override
  String get brandLogoImage => "images/picknsend/brand_logo.png";

  @override
  String get brandLogoImageDark => "images/picknsend/brand_logo.png";

  @override
  String get centerIconImage => "images/picknsend/icon.png";

  @override
  String get androidAnalyticsAppId => "c9ad4dc7-b6ef-432a-b930-ff6242d168fb";

  @override
  String get iphoneAnalyticsAppId => "ad903857-69c7-4438-bdee-c3a9e52c58b0";

  @override
  String get companyId => "721f4027-6897-47bb-9103-f25a78c38473";

  @override
  String get metricsPrefixKey => "PICKNSEND";

  @override
  String get pushChannelTopic => "PICKNSEND";

  @override
  double get centerIconSize => 80;
  @override
  double get centerInactiveIconSize => 35;
}
