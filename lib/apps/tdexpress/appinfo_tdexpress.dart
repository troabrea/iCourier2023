import 'package:firebase_core/firebase_core.dart';

import '../appinfo.dart';

class TdExpressAppInfo extends AppInfo {
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
  String get brandLogoImage => "images/tdexpress/brand_logo.png";
  @override
  String get brandLogoImageDark => "images/tdexpress/brand_logo.png";
  @override
  String get centerIconImage => "images/tdexpress/icon.png";

  @override
  String get androidAnalyticsAppId => "bc303da8-ca21-428d-a477-ba4bc72c1d8a";

  @override
  String get iphoneAnalyticsAppId => "280d396c-03dd-426f-b34c-3e7fb717ae9e";

  @override
  String get companyId => "9212e43c-5281-4dd4-b6ff-80b06725b646";

  @override
  String get metricsPrefixKey => "TDEXPRESS";

  @override
  String get pushChannelTopic => "TDEXPRESS";

  @override
  double get centerIconSize => 80;
  @override
  double get centerInactiveIconSize => 35;
}
