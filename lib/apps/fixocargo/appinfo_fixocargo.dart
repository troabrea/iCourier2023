import 'package:firebase_core/firebase_core.dart';
import 'package:icourier/apps/fixocargo/firebase_options_fixocargo.dart';

import '../appinfo.dart';

class FixocargoAppInfo extends AppInfo {
  @override
  // TODO: implement appFirebaseOptions
  FirebaseOptions get appFirebaseOptions =>
      FixoCargoDefaultFirebaseOptions.currentPlatform;
  @override
  String defaultLocale = 'es';
  @override
  String additionalLocale = '';
  @override
  String currencyCode = 'RD\$';

  @override
  int defaultTab = 2;
  @override
  String get iphoneAnalyticsAppId => "d4902556-b9b6-4716-9129-62b209461e0f";

  @override
  String get androidAnalyticsAppId => "9e9aa81d-7fa0-4d69-8162-5579cd005d7e";

  @override
  String get brandLogoImage => "images/fixocargo/brand_logo.png";
  @override
  String get brandLogoImageDark => "images/fixocargo/brand_logo.png";
  @override
  String get centerIconImage => "images/fixocargo/icon.png";

  @override
  double get centerIconSize => 45;

  @override
  double get centerInactiveIconSize => 35;

  @override
  String get companyId => "257de406-e7d8-41ec-8195-2b2113e393e9";

  @override
  String get metricsPrefixKey => "FIXOCARGO";

  @override
  String get pushChannelTopic => "FIXOCARGO";
}
