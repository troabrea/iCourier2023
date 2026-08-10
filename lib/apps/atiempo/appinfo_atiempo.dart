import 'package:firebase_core/firebase_core.dart';
import 'package:icourier/apps/atiempo/firebase_options_atiempo.dart';

import '../appinfo.dart';

class AtiempoAppInfo extends AppInfo {
  @override
  FirebaseOptions appFirebaseOptions =
      ATiempoDefaultFirebaseOptions.currentPlatform;

  @override
  String defaultLocale = 'es';
  @override
  String additionalLocale = '';

  @override
  String currencyCode = 'RD\$';

  @override
  int defaultTab = 2;

  @override
  String get brandLogoImage => "images/atiempo/brand_logo.png";
  @override
  String get brandLogoImageDark => "images/atiempo/brand_logo.png";
  @override
  String get centerIconImage => "images/atiempo/icon.png";

  @override
  String get androidAnalyticsAppId => "ATIEMPO";

  @override
  String get iphoneAnalyticsAppId => "ATIEMPO";

  @override
  String get companyId => "f1fc0289-3196-447d-a147-a10874350c2c";

  @override
  String get metricsPrefixKey => "ATIEMPO";

  @override
  String get pushChannelTopic => "ATIEMPO";

  @override
  double get centerIconSize => 80;
  @override
  double get centerInactiveIconSize => 35;
}
