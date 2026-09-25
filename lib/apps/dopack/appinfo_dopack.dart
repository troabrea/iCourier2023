import 'package:firebase_core/firebase_core.dart';
import 'package:icourier/apps/dopack/firebase_options_dopack.dart';

import '../appinfo.dart';

class DoPackAppInfo extends AppInfo {
  @override
  FirebaseOptions appFirebaseOptions =
      DoPackDefaultFirebaseOptions.currentPlatform;

  @override
  String defaultLocale = 'es';
  @override
  String additionalLocale = '';

  @override
  String currencyCode = 'RD\$';

  @override
  int defaultTab = 2;

  @override
  String get brandLogoImage => 'images/dopack/brand_logo.png';
  @override
  String get brandLogoImageDark => 'images/dopack/brand_logo.png';
  @override
  String get centerIconImage => 'images/dopack/icon.png';

  @override
  String get androidAnalyticsAppId => 'DOPACK';

  @override
  String get iphoneAnalyticsAppId => 'DOPACK';

  @override
  String get companyId => '7a60bee3-6639-4340-a791-3402b29dd96e';

  @override
  String get metricsPrefixKey => 'DOPACK';

  @override
  String get pushChannelTopic => 'DOPACK';

  @override
  double get centerIconSize => 80;
  @override
  double get centerInactiveIconSize => 35;
}
