import 'package:firebase_core/firebase_core.dart';
import 'package:icourier/apps/inbox/firebase_options_inbox.dart';

import '../appinfo.dart';

class InboxAppInfo extends AppInfo {
  @override
  // TODO: implement appFirebaseOptions
  FirebaseOptions get appFirebaseOptions =>
      InboxDefaultFirebaseOptions.currentPlatform;
  @override
  String defaultLocale = 'es';
  @override
  String additionalLocale = '';
  @override
  String currencyCode = 'RD\$';

  @override
  int defaultTab = 2;

  @override
  String get brandLogoImage => "images/inbox/brand_logo.png";

  @override
  String get brandLogoImageDark => "images/inbox/brand_logo.png";

  @override
  String get centerIconImage => "images/inbox/icon.png";

  @override
  String get androidAnalyticsAppId => "a43fa9bb-bb66-4bc4-b6f9-bbbe57a99a7f";

  @override
  String get iphoneAnalyticsAppId => "53733f12-2741-49dc-92fa-69d1b0eed89f";

  @override
  String get companyId => "46ead561-5beb-4466-8112-803fa3e3e1eb";

  @override
  String get metricsPrefixKey => "INBOX";

  @override
  String get pushChannelTopic => "INBOX";

  @override
  double get centerIconSize => 60;
  @override
  double get centerInactiveIconSize => 40;
}
