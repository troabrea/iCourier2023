import 'package:firebase_core/firebase_core.dart';

import '../appinfo.dart';
import 'firebase_options_bmcargo.dart';

class BmcargoAppInfo extends AppInfo {
  @override
  // TODO: implement appFirebaseOptions
  FirebaseOptions get appFirebaseOptions =>
      BmCargoDefaultFirebaseOptions.currentPlatform;
  @override
  String defaultLocale = 'es';
  @override
  String additionalLocale = 'en';

  @override
  String currencyCode = 'RD\$';

  @override
  int defaultTab = 2;

  @override
  String get brandLogoImage => "images/bmcargo/brand_logo.png";
  @override
  String get brandLogoImageDark => "images/bmcargo/brand_logo.png";
  @override
  String get centerIconImage => "images/bmcargo/icon.png";

  @override
  String get androidAnalyticsAppId => "247cad1f-bfbc-4555-8478-9b5a3ef3dd38";

  @override
  String get iphoneAnalyticsAppId => "36f996a0-1672-494a-a31c-471944da8f1d";

  @override
  String get companyId => "ebb66ab7-db15-4267-9ef4-92abcb5273eb";

  @override
  String get metricsPrefixKey => "BMCARGO";

  @override
  String get pushChannelTopic => "BMCARGO";

  @override
  double get centerIconSize => 80;
  @override
  double get centerInactiveIconSize => 35;
}
