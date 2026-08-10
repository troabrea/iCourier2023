import 'package:firebase_core/firebase_core.dart';
import 'package:icourier/apps/beexpress/firebase_options_beexpress.dart';

import '../appinfo.dart';

class BeexpressAppInfo extends AppInfo {
  @override
  // TODO: implement appFirebaseOptions
  FirebaseOptions get appFirebaseOptions =>
      BeExpressDefaultFirebaseOptions.currentPlatform;
  @override
  String defaultLocale = 'es';
  @override
  String additionalLocale = '';

  @override
  String currencyCode = 'RD\$';

  @override
  int defaultTab = 2;

  @override
  String get brandLogoImage => "images/beexpress/brand_logo.png";
  @override
  String get brandLogoImageDark => "images/beexpress/brand_logo.png";
  @override
  String get centerIconImage => "images/beexpress/icon.png";

  @override
  String get androidAnalyticsAppId => "197a4477-ffd0-4997-9899-78b46a1b9c50";

  @override
  String get iphoneAnalyticsAppId => "705e82c6-6352-4a6a-a3ff-388b51ad2eef";

  @override
  String get companyId => "CA9BE28A-F671-41B6-BD48-A4EF25589F27";

  @override
  String get metricsPrefixKey => "BEEXPRESS";

  @override
  String get pushChannelTopic => "BEEXPRESS";

  @override
  double get centerIconSize => 80;
  @override
  double get centerInactiveIconSize => 35;
}
