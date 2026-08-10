import 'package:firebase_core/firebase_core.dart';

import '../appinfo.dart';

class TeloAppInfo extends AppInfo {
  @override
  // TODO: implement appFirebaseOptions
  FirebaseOptions get appFirebaseOptions => throw UnimplementedError();
  @override
  String defaultLocale = 'es';
  @override
  String additionalLocale = '';
  @override
  String currencyCode = 'RD\$';

  @override
  int defaultTab = 2;

  @override
  String get brandLogoImage => "images/telo/brand_logo.png";
  @override
  String get brandLogoImageDark => "images/telo/brand_logo_dark.png";
  @override
  String get centerIconImage => "images/telo/icon.png";

  @override
  String get androidAnalyticsAppId => "a8670634-3869-4561-9257-e830015b273c";

  @override
  String get iphoneAnalyticsAppId => "a8670634-3869-4561-9257-e830015b273c";

  @override
  String get companyId => "a8670634-3869-4561-9257-e830015b273c";

  @override
  String get metricsPrefixKey => "TELO";

  @override
  String get pushChannelTopic => "TELO";

  @override
  double get centerIconSize => 60;
  @override
  double get centerInactiveIconSize => 30;
}
