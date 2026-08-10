import 'package:firebase_core/firebase_core.dart';
import 'package:icourier/apps/taino/firebase_options_taino.dart';

import '../appinfo.dart';

class TainoAppInfo extends AppInfo {
  @override
  // TODO: implement appFirebaseOptions
  FirebaseOptions get appFirebaseOptions =>
      TainoDefaultFirebaseOptions.currentPlatform;
  @override
  String defaultLocale = 'es';
  @override
  String additionalLocale = '';
  @override
  String currencyCode = 'RD\$';

  @override
  int defaultTab = 2;
  @override
  String get iphoneAnalyticsAppId => "1be0433e-677e-4423-97d9-200895450b4d";

  @override
  String get androidAnalyticsAppId => "456aafaa-d8b6-44e7-96f1-ae1d7ceb4853";

  @override
  String get brandLogoImage => "images/taino/brand_logo.png";
  @override
  String get brandLogoImageDark => "images/taino/brand_logo.png";
  @override
  String get centerIconImage => "images/taino/icon.png";

  @override
  double get centerIconSize => 35;

  @override
  double get centerInactiveIconSize => 35;

  @override
  String get companyId => "678cf44a-4996-4002-81fa-a4d170f4f7c0";

  @override
  String get metricsPrefixKey => "TAINO";

  @override
  String get pushChannelTopic => "TAINO";
}
