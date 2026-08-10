import 'package:firebase_core/firebase_core.dart';

import '../appinfo.dart';
import 'firebase_options_cainca.dart';

class CaincaAppInfo extends AppInfo {
  @override
  FirebaseOptions get appFirebaseOptions =>
      CaincaDefaultFirebaseOptions.currentPlatform;
  @override
  String defaultLocale = 'es';
  @override
  String additionalLocale = '';
  @override
  String currencyCode = 'RD\$';

  @override
  int defaultTab = 2;

  @override
  String get brandLogoImage => "images/cainca/brand_logo.png";

  @override
  String get brandLogoImageDark => "images/cainca/brand_logo.png";

  @override
  String get centerIconImage => "images/cainca/icon.png";

  @override
  String get androidAnalyticsAppId => "a20efa59-6d18-4130-a8e8-0696f3568861";

  @override
  String get iphoneAnalyticsAppId => "497f10bd-a295-4662-af98-25a6c01e4193";

  @override
  String get companyId => "b88a3bc9-0d0d-4a2f-ac47-5236e2d9dcd2";

  @override
  String get metricsPrefixKey => "CAINCA";

  @override
  String get pushChannelTopic => "CAINCA";

  @override
  double get centerIconSize => 60;
  @override
  double get centerInactiveIconSize => 40;
}
