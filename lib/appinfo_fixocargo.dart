import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

import 'appinfo.dart';

class FixocargoAppInfo implements AppInfo {
  @override
  int defaultTab = 0;
  @override
  String get iphoneAnalyticsAppId => "d4902556-b9b6-4716-9129-62b209461e0f";

  @override
  String get androidAnalyticsAppId => "9e9aa81d-7fa0-4d69-8162-5579cd005d7e";

  @override
  String get brandLogoImage => "images/fixocargo/brand_logo.png";

  @override
  String get centerIconImage => "images/fixocargo/icon.png";

  @override
  double get centerIconSize => 35;

  @override
  double get centerInactiveIconSize => 35;

  @override
  String get companyId => "257de406-e7d8-41ec-8195-2b2113e393e9";



  @override
  String get metricsPrefixKey => "FIXOCARGO";

  @override
  String get pushChannelTopic => "FIXOCARGO";


  @override //#b42129 #d2ab77
  ThemeData getDarkTheme() {
    const primaryColor = Color(0xff131d32);
    const secondaryColor = Color(0xff131d32); //Color(0xffffb74d);
    // const primaryVariantColor = Color(0xff2b52b7);
    const errorColor = Color(0xff131d32);
    getDarkAppBarTheme() {
      return AppBarTheme(iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(fontFamily: 'Myriad', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 22),
        backgroundColor: primaryColor.darken(10),
        foregroundColor: Colors.white,
      );
    }
    // getDarkAppBarTheme2() {
    //   return const AppBarTheme(iconTheme: IconThemeData(color: Colors.black),
    //       actionsIconTheme: IconThemeData(color: Colors.black),
    //       titleTextStyle: TextStyle(fontFamily: 'Myriad', fontWeight: FontWeight.bold, color: primaryColor, fontSize: 22),
    //       backgroundColor: Colors.black,
    //       foregroundColor: primaryColor);
    // }
    // getDarkDialogTheme() {
    //   return const DialogTheme(titleTextStyle: TextStyle(fontFamily: 'Myriad', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20));
    // }
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
        headlineMedium: TextStyle(
          fontFamily: 'Myriad',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: secondaryColor,
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
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
      ),
      fontFamily: 'Myriad',
      usedColors: 3,
      //surfaceMode: FlexSurfaceMode.highBackgroundLowScaffold,
      blendLevel: 15,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 15,
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
        .copyWith(
        errorColor: errorColor,
        dividerColor: Colors.white30,
        primaryColorDark: Colors.white70,
        iconTheme: const IconThemeData(color: primaryColor),
        elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom( padding: const EdgeInsets.all(6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)), backgroundColor: secondaryColor, foregroundColor: Colors.white ) ),
        textTheme:  getDarkTextTheme(),
        appBarTheme: getDarkAppBarTheme()
    );
  }

  @override
  ThemeData getLightTheme() {
    const primaryColor = Color(0xff131d32);
    const secondaryColor = Color(0xff131d32); //Color(0xffffb74d);
    const primaryVariantColor = Color(0xff131d32);
    const errorColor = Color(0xff131d32);

    getLightAppBarTheme() {
      return const AppBarTheme(iconTheme: IconThemeData(color: Colors.white),
          actionsIconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(fontFamily: 'Myriad', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 22), backgroundColor: primaryColor,foregroundColor: Colors.white);
    }
    // getLightDialogTheme() {
    //   return const DialogTheme(titleTextStyle: TextStyle(fontFamily: 'Myriad', fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20));
    // }
    getLightTextButtonTheme() {
      return TextButtonThemeData( style: TextButton.styleFrom(foregroundColor: primaryVariantColor, textStyle: const TextStyle(fontFamily: 'Myriad', fontWeight: FontWeight.bold, fontSize: 16)  ) );
    }
    getLightTextTheme() {
      return const TextTheme(
        titleLarge: TextStyle(
          fontFamily: 'Myriad',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: secondaryColor,
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
        headlineMedium: TextStyle(
          fontFamily: 'Myriad',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: secondaryColor,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Myriad',
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: secondaryColor,
        ),
      );
    }

    return FlexThemeData.light(
      colors: const FlexSchemeColor(
          primary: primaryColor,
          secondary: secondaryColor,
          appBarColor: primaryColor,
          error: errorColor
      ),
      // colors: const FlexSchemeColor(
      //   primary: primaryColor,
      //   primaryContainer: Color(0xffd0e4ff),
      //   secondary: secondaryColor,
      //   secondaryContainer: Color(0xfff7d701),
      //   tertiary: primaryColor,
      //   tertiaryContainer: Color(0xfff7d701),
      //   appBarColor: primaryColor,
      //   error: Color(0xffb00020),
      // ),
      fontFamily: 'Myriad',
      //surfaceMode: FlexSurfaceMode.highScaffoldLevelSurface, // .highScaffoldLowSurface,
      blendLevel: 3,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 3,
        //blendOnColors: true,
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
        .copyWith(
        dividerColor: Colors.black12,
        elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom( padding: const EdgeInsets.all(6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)) ,  backgroundColor: secondaryColor, foregroundColor: Colors.white ) ) ,
        textTheme:  getLightTextTheme(),
        iconTheme: const IconThemeData(color: primaryColor),
        textButtonTheme: getLightTextButtonTheme(),
        appBarTheme: getLightAppBarTheme()
    );
  }


}