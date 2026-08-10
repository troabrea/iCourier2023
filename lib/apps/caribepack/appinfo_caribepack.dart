import 'package:firebase_core/firebase_core.dart';

import '../appinfo.dart';
import 'firebase_options_caribepack.dart';

class CaribepackAppInfo extends AppInfo {
  @override
  // TODO: implement appFirebaseOptions
  FirebaseOptions get appFirebaseOptions =>
      CaribepackDefaultFirebaseOptions.currentPlatform;
  @override
  String defaultLocale = 'es';
  @override
  String additionalLocale = '';
  @override
  String currencyCode = 'RD\$';

  @override
  int defaultTab = 2;
  @override
  String get iphoneAnalyticsAppId => "834f33d7-eefc-4c94-980b-8fb82ed81114";

  @override
  String get androidAnalyticsAppId => "2202ed81-0fbb-4bcf-b051-4cf1bc9644ff";

  @override
  String get brandLogoImage => "images/caribepack/brand_logo.png";
  @override
  String get brandLogoImageDark => "images/caribepack/brand_logo.png";
  @override
  String get centerIconImage => "images/caribepack/icon.png";

  @override
  double get centerIconSize => 80;

  @override
  double get centerInactiveIconSize => 35;

  @override
  String get companyId => "64eff6a8-fa06-4a4e-8cfc-1d5a8d3a2b77";

  @override
  String get metricsPrefixKey => "CARIBEPACK";

  @override
  String get pushChannelTopic => "CARIBEPACK";
}
