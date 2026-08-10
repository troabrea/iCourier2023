import 'package:firebase_core/firebase_core.dart';
import 'package:icourier/apps/tupaq/firebase_options_tupaq.dart';

import '../appinfo.dart';

class TupaqAppInfo extends AppInfo {
  @override
  // TODO: implement appFirebaseOptions
  FirebaseOptions get appFirebaseOptions =>
      TuPaqDefaultFirebaseOptions.currentPlatform;
  @override
  String defaultLocale = 'es';
  @override
  String additionalLocale = '';
  @override
  int defaultTab = 2;

  @override
  String currencyCode = 'RD\$';

  @override
  String get brandLogoImage => "images/tupaq/brand_logo.png";

  @override
  String get brandLogoImageDark => "images/tupaq/brand_logo.png";

  @override
  String get centerIconImage => "images/tupaq/icon.png";

  @override
  String get androidAnalyticsAppId => "52cb660c-e8a2-451c-ad9a-53883c84f20f";

  @override
  String get iphoneAnalyticsAppId => "6f2c0f13-4c15-4d15-9433-5862e44fef47";

  @override
  String get companyId => "8894b096-f666-4787-9a86-69423090721b";

  @override
  String get metricsPrefixKey => "TUPAQ";

  @override
  String get pushChannelTopic => "TUPAQ";

  @override
  double get centerIconSize => 60;
  @override
  double get centerInactiveIconSize => 40;
}
