import 'package:firebase_core/firebase_core.dart';
import 'package:icourier/apps/atiempo/firebase_options_atiempo.dart';

import '../appinfo.dart';

class CargoWiseAppInfo extends AppInfo {
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
  String get brandLogoImage => "images/cargowise/brand_logo.png";

  @override
  String get brandLogoImageDark => "images/cargowise/brand_logo_dark.png";

  @override
  String get centerIconImage => "images/cargowise/icon.png";

  @override
  String get androidAnalyticsAppId => "";

  @override
  String get iphoneAnalyticsAppId => "";

  @override
  String get companyId => "a941cf79-3da1-4aeb-842e-1671c444d10a";

  @override
  String get metricsPrefixKey => "CARGOWISE";

  @override
  String get pushChannelTopic => "CARGOWISE";

  @override
  double get centerIconSize => 60;
  @override
  double get centerInactiveIconSize => 30;
}
