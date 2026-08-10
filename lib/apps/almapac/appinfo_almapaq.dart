import 'package:firebase_core/firebase_core.dart';
import 'package:icourier/apps/almapac/firebase_options_almapaq.dart';

import '../appinfo.dart';

class AlmapaqAppInfo extends AppInfo {
  @override
  FirebaseOptions get appFirebaseOptions =>
      AlmapaqDefaultFirebaseOptions.currentPlatform;

  @override
  String defaultLocale = 'es';
  @override
  String additionalLocale = '';

  @override
  String currencyCode = 'RD\$';

  @override
  int defaultTab = 2;

  @override
  String get brandLogoImage => "images/almapaq/brand_logo.png";
  @override
  String get brandLogoImageDark => "images/almapaq/brand_logo.png";
  @override
  String get centerIconImage => "images/almapaq/icon.png";

  @override
  String get androidAnalyticsAppId => "76ba5c2f-2da7-44e4-a6cc-9da1615ea0fe";

  @override
  String get iphoneAnalyticsAppId => "f2dfeae4-3762-4e43-8555-76baf34c4b2b";

  @override
  String get companyId => "51f1ac99-898e-46d3-9cd9-b6639addb1bf";

  @override
  String get metricsPrefixKey => "ALMAPAQ";

  @override
  String get pushChannelTopic => "ALMAPAQ";

  @override
  double get centerIconSize => 80;
  @override
  double get centerInactiveIconSize => 35;
}
