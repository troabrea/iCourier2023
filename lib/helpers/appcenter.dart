import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/apps/appinfo.dart';

class AppCenter {
  static void startAsync({required String appSecretIOS, required String appSecretAndroid, required bool enableCrashes, required bool enableAnalytics}) {

  }

  static void trackEventAsync(String s) {
    // Posthog().capture(eventName: s);
    // FirebaseAnalytics.instance.logScreenView( screenName: s, parameters: {
    //   "courier" : GetIt.I<AppInfo>().metricsPrefixKey
    // } );
    FirebaseAnalytics.instance.logEvent(name: s,parameters: {
      "courier" : GetIt.I<AppInfo>().metricsPrefixKey
    } );
  }

}