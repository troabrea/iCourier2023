import 'package:firebase_core/firebase_core.dart';
import 'package:icourier/apps/jetpack/firebase_options_jetpack.dart';

import '../appinfo.dart';

class JetpackAppInfo extends AppInfo {
  @override
  // TODO: implement appFirebaseOptions
  FirebaseOptions get appFirebaseOptions =>
      JetPackDefaultFirebaseOptions.currentPlatform;
  @override
  String defaultLocale = 'es';
  @override
  String additionalLocale = '';
  @override
  String currencyCode = 'RD\$';

  @override
  int defaultTab = 2;

  @override
  String get brandLogoImage => "images/jetpack/brand_logo.png";
  @override
  String get brandLogoImageDark => "images/jetpack/brand_logo.png";
  @override
  String get centerIconImage => "images/jetpack/icon.png";

  @override
  String get androidAnalyticsAppId => "2ce87430-3e9d-4cea-8ca1-d8c9d9b7571a";

  @override
  String get iphoneAnalyticsAppId => "ad903857-69c7-4438-bdee-c3a9e52c58b0";

  @override
  String get companyId => "763e7c33-149b-4738-889d-bd89ebcf4626";

  @override
  String get metricsPrefixKey => "JETPACK";

  @override
  String get pushChannelTopic => "JETPACK";

  @override
  double get centerIconSize => 80;
  @override
  double get centerInactiveIconSize => 35;
}
