import 'package:firebase_core/firebase_core.dart';
import 'package:icourier/apps/gopack/firebase_options_gopack.dart';

import '../appinfo.dart';

class GopackAppInfo extends AppInfo {
  @override
  // TODO: implement appFirebaseOptions
  FirebaseOptions get appFirebaseOptions =>
      GoPackDefaultFirebaseOptions.currentPlatform;
  @override
  String defaultLocale = 'es';
  @override
  String additionalLocale = '';
  @override
  String currencyCode = 'RD\$';

  @override
  int defaultTab = 2;

  @override
  String get brandLogoImage => "images/gopack/brand_logo.png";
  @override
  String get brandLogoImageDark => "images/gopack/brand_logo_dark.png";
  @override
  String get centerIconImage => "images/gopack/icon.png";

  @override
  String get androidAnalyticsAppId => "d23a5196-c82d-4821-babb-dd09655ca64f";

  @override
  String get iphoneAnalyticsAppId => "d23a5196-c82d-4821-babb-dd09655ca64f";

  @override
  String get companyId => "d23a5196-c82d-4821-babb-dd09655ca64f";

  @override
  String get metricsPrefixKey => "GOPACK";

  @override
  String get pushChannelTopic => "GOPACK";

  @override
  double get centerIconSize => 60;
  @override
  double get centerInactiveIconSize => 30;
}
