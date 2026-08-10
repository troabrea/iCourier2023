import 'package:firebase_core/firebase_core.dart';
import 'package:icourier/apps/cargospot/firebase_options_cargospot.dart';

import '../appinfo.dart';

class CargoSpotAppInfo extends AppInfo {
  @override
  FirebaseOptions appFirebaseOptions =
      CargoSpotDefaultFirebaseOptions.currentPlatform;

  @override
  String defaultLocale = 'es';
  @override
  String additionalLocale = '';

  @override
  String currencyCode = 'RD\$';

  @override
  int defaultTab = 2;

  @override
  String get brandLogoImage => "images/cargospot/brand_logo.png";

  @override
  String get brandLogoImageDark => "images/cargospot/brand_logo.png";

  @override
  String get centerIconImage => "images/cargospot/icon.png";

  @override
  String get androidAnalyticsAppId => "";

  @override
  String get iphoneAnalyticsAppId => "";

  @override
  String get companyId => "7fb41461-5a0b-488a-a949-a536aaa3b051";

  @override
  String get metricsPrefixKey => "CARGOSPOT";

  @override
  String get pushChannelTopic => "CARGOSPOT";

  @override
  double get centerIconSize => 60;
  @override
  double get centerInactiveIconSize => 30;
}
