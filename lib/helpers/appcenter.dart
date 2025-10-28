import 'package:posthog_flutter/posthog_flutter.dart';

class AppCenter {
  static void startAsync({required String appSecretIOS, required String appSecretAndroid, required bool enableCrashes, required bool enableAnalytics}) {

  }

  static void trackEventAsync(String s) {
    Posthog().capture(eventName: s);
  }

}