import 'package:firebase_core/firebase_core.dart';

import '../appinfo.dart';
import 'firebase_options_boxpaq.dart';

class BoxpaqAppInfo extends AppInfo {
  @override
  // TODO: implement appFirebaseOptions
  FirebaseOptions get appFirebaseOptions =>
      BoxpaqDefaultFirebaseOptions.currentPlatform;
  @override
  String defaultLocale = 'es';
  @override
  String additionalLocale = '';

  @override
  String currencyCode = 'RD\$';

  @override
  int defaultTab = 2;

  @override
  String get brandLogoImage => "images/boxpaq/brand_logo.png";
  @override
  String get brandLogoImageDark => "images/boxpaq/brand_logo.png";
  @override
  String get centerIconImage => "images/boxpaq/icon.png";

  @override
  String get androidAnalyticsAppId => "86480649-f71f-471f-9334-70e8b76db06c";

  @override
  String get iphoneAnalyticsAppId => "c2ff7eb4-1253-4381-91c7-4f415b955537";

  @override
  String get companyId => "487937a0-59f8-4083-bb2e-6c5bc69e7070";

  @override
  String get metricsPrefixKey => "BOXPAQ";

  @override
  String get pushChannelTopic => "BOXPAQ";

  @override
  double get centerIconSize => 80;
  @override
  double get centerInactiveIconSize => 35;
}
