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
  String get brandLogoImageDark;
  double get centerIconSize;
  double get centerInactiveIconSize;
  int defaultTab = 2;
  ThemeData getLightTheme();
  ThemeData getDarkTheme();
 }