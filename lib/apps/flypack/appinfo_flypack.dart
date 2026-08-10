import 'package:firebase_core/firebase_core.dart';
import 'package:icourier/apps/flypack/firebase_options_flypack.dart';

import '../appinfo.dart';

class FlypackAppInfo extends AppInfo {
  @override
  // TODO: implement appFirebaseOptions
  FirebaseOptions get appFirebaseOptions =>
      FlyPackDefaultFirebaseOptions.currentPlatform;
  @override
  String defaultLocale = 'es';
  @override
  String additionalLocale = '';
  @override
  String currencyCode = 'RD\$';

  @override
  int defaultTab = 2;

  @override
  String get brandLogoImage => "images/flypack/brand_logo.png";

  @override
  String get brandLogoImageDark => "images/flypack/brand_logo.png";

  @override
  String get centerIconImage => "images/flypack/icon.png";

  @override
  String get androidAnalyticsAppId => "4d6a4db6-ae2b-4f75-a55f-d1a5c7a8deca";

  @override
  String get iphoneAnalyticsAppId => "eaa244bd-cede-4acc-95bc-ffcbed630620";

  @override
  String get companyId => "4bebf933-fb93-4abc-8415-692b08a2b75e";

  @override
  String get metricsPrefixKey => "FLYPACK";

  @override
  String get pushChannelTopic => "FLYPACK";

  @override
  double get centerIconSize => 60;
  @override
  double get centerInactiveIconSize => 40;
}
