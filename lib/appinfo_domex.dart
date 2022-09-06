import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/material/theme_data.dart';

import 'appinfo.dart';

class DomexAppInfo implements AppInfo {

  @override
  String get androidAnalyticsAppId => "65b95f03-1311-4e28-8bf5-59dd28d6c125";

  @override
  String get iphoneAnalyticsAppId => "7194f9c7-2c86-488f-b41e-9dd39595c001";

  @override
  String get companyId => "08811d51-77bb-4a5b-a908-7d887632307d";

  @override
  String get metricsPrefixKey => "DOMEX";

  @override
  String get pushChannelTopic => "DOMEX";

  @override
  ThemeData getLightTheme() {
      Color primaryColor = const Color(0xfff7d701);

      getLightAppBarTheme() {
        return const AppBarTheme(iconTheme: IconThemeData(color: Colors.black),
            actionsIconTheme: IconThemeData(color: Colors.black),
            titleTextStyle: TextStyle(fontFamily: 'Myriad', fontWeight: FontWeight.bold, color: Colors.black, fontSize: 22), backgroundColor: Color(0xfff7d701),foregroundColor: Colors.black);
      }
      getLightDialogTheme() {
        return const DialogTheme(titleTextStyle: TextStyle(fontFamily: 'Myriad', fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20));
      }
      getLightTextButtonTheme() {
        return TextButtonThemeData( style: TextButton.styleFrom(foregroundColor: Colors.amber, textStyle: const TextStyle(fontFamily: 'Myriad', fontWeight: FontWeight.bold, fontSize: 16)  ) );
      }
      getLightTextTheme() {
        return const TextTheme(
          titleLarge: TextStyle(
            fontFamily: 'Myriad',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
          titleMedium: TextStyle(
            fontFamily: 'Myriad',
            fontSize: 18,
            color: Colors.black,
          ),
          titleSmall: TextStyle(
            fontFamily: 'Myriad',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black45,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Myriad',
            fontSize: 15,
            color: Colors.black,
          ),
          bodySmall: TextStyle(
            fontFamily: 'Myriad',
            fontSize: 12,
            color: Colors.black,
          ),
          headlineLarge: TextStyle(
            fontFamily: 'Myriad',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        );
      }

      return FlexThemeData.light(
        colors: const FlexSchemeColor(
          primary: Color(0xfff7d701),
          primaryContainer: Color(0xffd0e4ff),
          secondary: Color(0xff000000),
          secondaryContainer: Color(0xfff7d701),
          tertiary: Color(0xfff7d701),
          tertiaryContainer: Color(0xfff7d701),
          appBarColor: Color(0xfff7d701),
          error: Color(0xffb00020),
        ),
        fontFamily: 'Myriad',
        surfaceMode: FlexSurfaceMode.highScaffoldLevelSurface, // .highScaffoldLowSurface,
        blendLevel: 15,
        appBarOpacity: 1,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 15,
          blendOnColors: true,
          navigationBarLabelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        ),
        keyColors: const FlexKeyColors(
          useSecondary: true,
          keepPrimary: true,
          keepSecondary: true,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
      )
      .copyWith(elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom( backgroundColor: primaryColor, foregroundColor: Colors.black ) ) )
      .copyWith(textTheme:  getLightTextTheme())
      .copyWith(dialogTheme: getLightDialogTheme())
      .copyWith(textButtonTheme: getLightTextButtonTheme())
      .copyWith(appBarTheme: getLightAppBarTheme());
  }

  @override
  ThemeData getDarkTheme() {

    getDarkAppBarTheme() {
      return const AppBarTheme(iconTheme: IconThemeData(color: Colors.black),
          actionsIconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(fontFamily: 'Myriad', fontWeight: FontWeight.bold, color: Color(0xfff7d701), fontSize: 22),
          backgroundColor: Colors.black,
          foregroundColor: Color(0xfff7d701));
    }
    getDarkDialogTheme() {
      return const DialogTheme(titleTextStyle: TextStyle(fontFamily: 'Myriad', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20));
    }
    getDarkTextTheme() {
      return const TextTheme(
        titleLarge: TextStyle(
          fontFamily: 'Myriad',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Myriad',
          fontSize: 18,
          color: Colors.white,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Myriad',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white60,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Myriad',
          fontSize: 14,
          color: Colors.white,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Myriad',
          fontSize: 12,
          color: Colors.white,
        ),

        headlineLarge: TextStyle(
          fontFamily: 'Myriad',
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      );
    }

    return FlexThemeData.dark(
      colors: const FlexSchemeColor(
        primary: Color(0xfff7d701),
        primaryContainer: Color(0xffd0e4ff),
        secondary: Color(0xff000000),
        secondaryContainer: Color(0xfff7d701),
        tertiary: Color(0xfff7d701),
        tertiaryContainer: Color(0xfff7d701),
        appBarColor: Color(0xfff7d701),
        error: Color(0xffb00020),
      ),

      fontFamily: 'Myriad',
      usedColors: 3,
      surfaceMode: FlexSurfaceMode.highBackgroundLowScaffold,
      blendLevel: 15,
      appBarStyle: FlexAppBarStyle.background,

      appBarOpacity: 0.90,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 20,
        navigationBarLabelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      ),
      keyColors: const FlexKeyColors(
        useSecondary: true,
        keepPrimary: true,
        keepSecondary: true,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
    )
    //.copyWith(elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom( backgroundColor: primaryColor, foregroundColor: Colors.black ) ) )
    .copyWith(dialogTheme: getDarkDialogTheme())
    .copyWith(textTheme:  getDarkTextTheme())
    .copyWith(appBarTheme: getDarkAppBarTheme());
  }


}