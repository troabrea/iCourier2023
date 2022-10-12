import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/material/theme_data.dart';

import 'appinfo.dart';

class DomexAppInfo implements AppInfo {

  @override
  int defaultTab = 0;

  @override
  String get brandLogoImage => "images/domex/brand_logo.png";

  @override
  String get centerIconImage => "images/domex/icon.png";
  @override
  double get centerIconSize => 35;
  @override
  double get centerInactiveIconSize => 25;
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
      const primaryColor = Color(0xfff7d701);
      const secondaryColor = Color(0xff000000);

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
            color: Colors.black,
          ),
        );
      }

      return FlexThemeData.light(
        colors: const FlexSchemeColor(
          primary: primaryColor,
          secondary: secondaryColor,
          appBarColor: primaryColor,
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
        blendLevel: 15,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 15,
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
      .copyWith(elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom( padding: const EdgeInsets.symmetric(vertical: 6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)) , backgroundColor: secondaryColor, foregroundColor: primaryColor ) ) )
      .copyWith(textTheme:  getLightTextTheme())
      //.copyWith(dialogTheme: getLightDialogTheme())
      .copyWith(textButtonTheme: getLightTextButtonTheme())
      .copyWith(appBarTheme: getLightAppBarTheme());
  }

  @override
  ThemeData getDarkTheme() {
    const primaryColor = Color(0xfff7d701);
    const secondaryColor = Color(0xff000000);
    getDarkAppBarTheme() {
      return const AppBarTheme(
          iconTheme: IconThemeData(color: Colors.black),
          actionsIconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(fontFamily: 'Myriad', fontWeight: FontWeight.bold, color: Colors.black, fontSize: 22),
          toolbarTextStyle: TextStyle(fontFamily: 'Myriad', fontWeight: FontWeight.bold, color: Colors.black, fontSize: 22),
          backgroundColor: primaryColor,
          foregroundColor: Colors.black,);
    }
    getDarkAppBarTheme2() {
      return const AppBarTheme(iconTheme: IconThemeData(color: Colors.black),
          actionsIconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(fontFamily: 'Myriad', fontWeight: FontWeight.bold, color: primaryColor, fontSize: 22),
          backgroundColor: Colors.black,
          foregroundColor: primaryColor);
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
        headlineMedium: TextStyle(
          fontFamily: 'Myriad',
          fontSize: 18,
          fontWeight: FontWeight.w700,
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
        primary: primaryColor,
        secondary: secondaryColor,
      ),
      fontFamily: 'Myriad',
      usedColors: 3,
      //surfaceMode: FlexSurfaceMode.highBackgroundLowScaffold,
      blendLevel: 10,
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
    .copyWith(errorColor: Colors.red)
    //.copyWith(elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom( backgroundColor: primaryColor, foregroundColor: Colors.black ) ) )
    //.copyWith(dialogTheme: getDarkDialogTheme())
    .copyWith(textTheme:  getDarkTextTheme());
    //.copyWith(appBarTheme: getDarkAppBarTheme());
  }



}