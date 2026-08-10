import 'package:firebase_core/firebase_core.dart';
import 'package:icourier/apps/pintopaq/firebase_options_pintopaq.dart';

import '../appinfo.dart';

class PintopaqAppInfo extends AppInfo {
  @override
  // TODO: implement appFirebaseOptions
  FirebaseOptions get appFirebaseOptions =>
      PintoPaqDefaultFirebaseOptions.currentPlatform;
  @override
  String defaultLocale = 'es';
  @override
  String additionalLocale = '';
  @override
  String currencyCode = 'RD\$';

  @override
  int defaultTab = 2;

  @override
  String get brandLogoImage => "images/pintopaq/brand_logo.png";
  @override
  String get brandLogoImageDark => "images/pintopaq/brand_logo.png";
  @override
  String get centerIconImage => "images/pintopaq/icon.png";

  @override
  String get androidAnalyticsAppId => "ba8240cd-f0fe-42fe-b8f4-38a1ca4c169a";

  @override
  String get iphoneAnalyticsAppId => "a01379ba-0851-49eb-a70c-27063a07152a";

  @override
  String get companyId => "cd61da82-c461-4f19-9b3e-1dfb73274dfe";

  @override
  String get metricsPrefixKey => "PINTOPAQ";

  @override
  String get pushChannelTopic => "PINTOPAQ";

  @override
  double get centerIconSize => 42;
  @override
  double get centerInactiveIconSize => 35;
}
