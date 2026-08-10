import 'package:firebase_core/firebase_core.dart';
import 'package:icourier/apps/qm/firebase_options_qm.dart';

import '../appinfo.dart';

class QmAppInfo extends AppInfo {
  @override
  // TODO: implement appFirebaseOptions
  FirebaseOptions get appFirebaseOptions =>
      QmDefaultFirebaseOptions.currentPlatform;
  @override
  String defaultLocale = 'es';
  @override
  String additionalLocale = '';
  @override
  String currencyCode = 'RD\$';

  @override
  int defaultTab = 2;

  @override
  String get brandLogoImage => "images/qm/brand_logo.png";

  @override
  String get brandLogoImageDark => "images/qm/brand_logo.png";

  @override
  String get centerIconImage => "images/qm/icon.png";

  @override
  String get androidAnalyticsAppId => "087284b8-1444-4ae3-83b5-1a15b4405ffe";

  @override
  String get iphoneAnalyticsAppId => "d3872e1a-62e1-4c61-ab56-55a9137d5337";

  @override
  String get companyId => "900fb00c-2037-46fc-8afe-c5458740314c";

  @override
  String get metricsPrefixKey => "QM";

  @override
  String get pushChannelTopic => "QM";

  @override
  double get centerIconSize => 60;
  @override
  double get centerInactiveIconSize => 40;
}
