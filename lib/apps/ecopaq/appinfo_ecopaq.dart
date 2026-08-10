import 'package:firebase_core/firebase_core.dart';
import 'package:icourier/apps/ecopaq/firebase_options_ecopaq.dart';

import '../appinfo.dart';

class EcopaqAppInfo extends AppInfo {
  @override
  // TODO: implement appFirebaseOptions
  FirebaseOptions get appFirebaseOptions =>
      EcoPaqDefaultFirebaseOptions.currentPlatform;
  @override
  String defaultLocale = 'es';
  @override
  String additionalLocale = '';
  @override
  String currencyCode = 'RD\$';

  @override
  int defaultTab = 2;

  @override
  String get brandLogoImage => "images/ecopaq/brand_logo.png";

  @override
  String get brandLogoImageDark => "images/ecopaq/brand_logo.png";

  @override
  String get centerIconImage => "images/ecopaq/icon.png";

  @override
  String get androidAnalyticsAppId => "96fe39c3-ac76-4913-b06d-04635576f280";

  @override
  String get iphoneAnalyticsAppId => "063e8c59-2b15-448e-98b6-60d670a51af7";

  @override
  String get companyId => "b04c3785-d9a5-4bb9-9bf5-f828e091ec79";

  @override
  String get metricsPrefixKey => "ECOPAQ";

  @override
  String get pushChannelTopic => "ECOPAQ";

  @override
  double get centerIconSize => 60;
  @override
  double get centerInactiveIconSize => 40;
}
