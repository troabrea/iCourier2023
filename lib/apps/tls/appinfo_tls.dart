import 'package:firebase_core/firebase_core.dart';
import 'package:icourier/apps/tls/firebase_options_tls.dart';

import '../appinfo.dart';

class TlsAppInfo extends AppInfo {
  @override
  // TODO: implement appFirebaseOptions
  FirebaseOptions get appFirebaseOptions =>
      TlsDefaultFirebaseOptions.currentPlatform;
  @override
  String defaultLocale = 'es';
  @override
  String additionalLocale = '';
  @override
  String currencyCode = 'RD\$';

  @override
  int defaultTab = 2;

  @override
  String get brandLogoImage => "images/tls/brand_logo.png";

  @override
  String get brandLogoImageDark => "images/tls/brand_logo.png";

  @override
  String get centerIconImage => "images/tls/icon.png";

  @override
  String get androidAnalyticsAppId => "1e5c3d46-2323-4906-aa0b-6377fa84701d";

  @override
  String get iphoneAnalyticsAppId => "d865fffd-b98e-418f-a13f-f380ca7a292a";

  @override
  String get companyId =>
      "6b595d5d-98d2-4e5f-b9de-5ddb03774e95"; // "a2695534-9b0d-424f-949c-bb9d5cb453ce";

  @override
  String get metricsPrefixKey => "TLS";

  @override
  String get pushChannelTopic => "TLS";

  @override
  double get centerIconSize => 120;
  @override
  double get centerInactiveIconSize => 60;
}
