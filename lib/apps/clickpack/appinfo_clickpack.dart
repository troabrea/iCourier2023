import 'package:firebase_core/firebase_core.dart';
import 'package:icourier/apps/clickpack/firebase_options_clickpack.dart';

import '../appinfo.dart';

class ClickPackAppInfo extends AppInfo {
  @override
  // TODO: implement appFirebaseOptions
  FirebaseOptions get appFirebaseOptions =>
      ClickPackDefaultFirebaseOptions.currentPlatform;

  @override
  String defaultLocale = 'es';
  @override
  String additionalLocale = '';
  @override
  String currencyCode = 'RD\$';

  @override
  int defaultTab = 2;

  @override
  String get brandLogoImage => "images/clickpack/brand_logo.png";

  @override
  String get brandLogoImageDark => "images/clickpack/brand_logo.png";

  @override
  String get centerIconImage => "images/clickpack/icon.png";

  @override
  String get androidAnalyticsAppId => "ec751562-dbac-49c2-bec2-b3694ff32291";

  @override
  String get iphoneAnalyticsAppId => "a51b251d-f408-4f91-83b5-35ff2e34cc88";

  @override
  String get companyId => "1e4e20c1-6975-4f38-8e4f-f7a638aebc4f";

  @override
  String get metricsPrefixKey => "CLICKPACK";

  @override
  String get pushChannelTopic => "CLICKPACK";

  @override
  double get centerIconSize => 60;
  @override
  double get centerInactiveIconSize => 40;
}
