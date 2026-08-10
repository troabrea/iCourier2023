import 'package:firebase_core/firebase_core.dart';

import '../appinfo.dart';
import 'firebase_options_encargopaq.dart';

class EncargopaqAppInfo extends AppInfo {
  @override
  // TODO: implement appFirebaseOptions
  FirebaseOptions get appFirebaseOptions =>
      EncargopaqDefaultFirebaseOptions.currentPlatform;
  @override
  String defaultLocale = 'es';
  @override
  String additionalLocale = '';
  @override
  String currencyCode = 'RD\$';

  @override
  int defaultTab = 2;

  @override
  String get brandLogoImage => "images/encargopaq/brand_logo.png";
  @override
  String get brandLogoImageDark => "images/encargopaq/brand_logo.png";
  @override
  String get centerIconImage => "images/encargopaq/icon.png";

  @override
  String get androidAnalyticsAppId => "d2c07d2a-b021-407b-a855-c7c18e3f9bc6";

  @override
  String get iphoneAnalyticsAppId => "8854a5aa-0538-4ddb-af77-52e08225f598";

  @override
  String get companyId => "12d61b6e-32e2-4365-a91e-3b0070ac6497";

  @override
  String get metricsPrefixKey => "ENCARGOPAQ";

  @override
  String get pushChannelTopic => "ENCARGOPAQ";

  @override
  double get centerIconSize => 60;
  @override
  double get centerInactiveIconSize => 30;
}
