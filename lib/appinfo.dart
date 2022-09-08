import 'package:flutter/material.dart';

abstract class AppInfo
{
  String get companyId;
  String get iphoneAnalyticsAppId;
  String get androidAnalyticsAppId;
  String get metricsPrefixKey;
  String get pushChannelTopic;
  String get centerIconImage;
  String get brandLogoImage;
  ThemeData getLightTheme();
  ThemeData getDarkTheme();
}

