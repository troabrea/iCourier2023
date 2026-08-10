import 'package:firebase_core/firebase_core.dart';
import 'package:icourier/apps/domex/firebase_options_domex.dart';

import '../appinfo.dart';

class DomexAppInfo extends AppInfo {
  @override
  // TODO: implement appFirebaseOptions
  FirebaseOptions get appFirebaseOptions =>
      DomexDefaultFirebaseOptions.currentPlatform;
  @override
  String defaultLocale = 'es';
  @override
  String additionalLocale = '';
  @override
  int defaultTab = 2;

  @override
  String currencyCode = 'RD\$';

  @override
  String get brandLogoImage => "images/domex/brand_logo.png";
  @override
  String get brandLogoImageDark => "images/domex/brand_logo.png";
  @override
  String get centerIconImage => "images/domex/icon.png";
  @override
  double get centerIconSize => 35;
  @override
  double get centerInactiveIconSize => 25;
  @override
  String get androidAnalyticsAppId => "65b95f03-1311-4e28-8bf5-59dd28d6c125";

  @override
  String get iphoneAnalyticsAppId => "7194f9c7-2c86-488f-b41e-9dd39595c001";

  @override
  String get companyId => "08811d51-77bb-4a5b-a908-7d887632307d";

  @override
  String get metricsPrefixKey => "DOMEX";

  @override
  String get pushChannelTopic => "DOMEX";
}
