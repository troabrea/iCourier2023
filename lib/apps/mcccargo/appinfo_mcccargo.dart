import 'package:firebase_core/firebase_core.dart';
import 'package:icourier/apps/mcccargo/firebase_options_mcccargo.dart';

import '../appinfo.dart';

class MccCargoAppInfo extends AppInfo {
  @override
  FirebaseOptions get appFirebaseOptions =>
      MccCargoDefaultFirebaseOptions.currentPlatform;
  @override
  String defaultLocale = 'es';
  @override
  String additionalLocale = '';
  @override
  String currencyCode = 'RD\$';

  @override
  int defaultTab = 2;

  @override
  String get brandLogoImage => "images/mcccargo/brand_logo.png";

  @override
  String get brandLogoImageDark => "images/mcccargo/brand_logo.png";

  @override
  String get centerIconImage => "images/mcccargo/icon.png";

  @override
  String get androidAnalyticsAppId => "208dfe36-b56e-47ce-a721-89b3d037c594";

  @override
  String get iphoneAnalyticsAppId => "bf0f6706-0f71-4789-8a8d-b064d6afc228";

  @override
  String get companyId => "4d57b3bd-f19a-4985-b845-0f3457b4cc0c";

  @override
  String get metricsPrefixKey => "MCCCARGO";

  @override
  String get pushChannelTopic => "MCCCARGO";

  @override
  double get centerIconSize => 60;
  @override
  double get centerInactiveIconSize => 40;
}
