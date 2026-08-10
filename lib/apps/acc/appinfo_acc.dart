import 'package:firebase_core/firebase_core.dart';
import 'package:icourier/apps/acc/firebase_options_acc.dart';

import '../appinfo.dart';

class AccAppInfo extends AppInfo {
  @override
  FirebaseOptions appFirebaseOptions =
      AccDefaultFirebaseOptions.currentPlatform;

  @override
  String defaultLocale = 'es';
  @override
  String additionalLocale = '';

  @override
  String currencyCode = 'RD\$';

  @override
  int defaultTab = 2;

  @override
  String get brandLogoImage => "images/acc/brand_logo.png";
  @override
  String get brandLogoImageDark => "images/acc/brand_logo.png";
  @override
  String get centerIconImage => "images/acc/icon.png";

  @override
  String get androidAnalyticsAppId => "ACC";

  @override
  String get iphoneAnalyticsAppId => "ACC";

  @override
  String get companyId => "4fb3b0f1-fe6c-4f13-bd7c-d40f35eb9cf4";

  @override
  String get metricsPrefixKey => "ACC";

  @override
  String get pushChannelTopic => "ACC";

  @override
  double get centerIconSize => 80;
  @override
  double get centerInactiveIconSize => 35;
}
