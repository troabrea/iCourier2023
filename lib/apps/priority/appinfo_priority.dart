import 'package:firebase_core/firebase_core.dart';
import 'package:icourier/apps/priority/firebase_options.dart';

import '../appinfo.dart';

class PriorityAppInfo extends AppInfo {
  @override
  // TODO: implement appFirebaseOptions
  FirebaseOptions get appFirebaseOptions =>
      PriorityDefaultFirebaseOptions.currentPlatform;
  @override
  String defaultLocale = 'es';
  @override
  String additionalLocale = '';
  @override
  String currencyCode = 'RD\$';

  @override
  int defaultTab = 2;

  @override
  String get brandLogoImage => "images/priority/brand_logo.png";

  @override
  String get brandLogoImageDark => "images/priority/brand_logo_dark.png";

  @override
  String get centerIconImage => "images/priority/icon.png";

  @override
  String get androidAnalyticsAppId => "a3665b6d-ed91-438b-bf57-cc6d8e80a89e";

  @override
  String get iphoneAnalyticsAppId => "9d2dde3e-4547-4afb-a591-1fee1860733e";

  @override
  String get companyId => "3790d335-af0c-4253-aa5b-e622ac4562fa";

  @override
  String get metricsPrefixKey => "PRIORITY";

  @override
  String get pushChannelTopic => "PRIORITY";

  @override
  double get centerIconSize => 60;
  @override
  double get centerInactiveIconSize => 40;
}
