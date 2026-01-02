import 'package:firebase_core/firebase_core.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icourier/apps/atiempo/firebase_options_atiempo.dart';

import '../appinfo.dart';

class CargoWiseAppInfo implements AppInfo {
  @override
  FirebaseOptions appFirebaseOptions = ATiempoDefaultFirebaseOptions.currentPlatform;

  @override
  String defaultLocale = 'es';
  @override
  String additionalLocale = '';

  @override
  String currencyCode = 'RD\$';

  @override
  int defaultTab = 2;

  @override
  String get brandLogoImage => "images/cargowise/brand_logo.png";

  @override
  String get brandLogoImageDark => "images/cargowise/brand_logo_dark.png";

  @override
  String get centerIconImage => "images/cargowise/icon.png";

  @override
  String get androidAnalyticsAppId => "";

  @override
  String get iphoneAnalyticsAppId => "";

  @override
  String get companyId => "a941cf79-3da1-4aeb-842e-1671c444d10a";

  @override
  String get metricsPrefixKey => "CARGOWISE";

  @override
  String get pushChannelTopic => "CARGOWISE";

  @override
  double get centerIconSize => 60;
  @override
  double get centerInactiveIconSize => 30;

  @override
  ThemeData getLightTheme() {
    const primaryColor = Color(0xff203627);
    const secondaryColor = Color(0xffCBDB2A);
    const primaryVariantColor = Color(0xff0D0D0D);
    const errorColor = Color(0xffb00020);

    getLightAppBarTheme() {
      return const AppBarTheme(iconTheme: IconThemeData(color: Colors.white),
          systemOverlayStyle: SystemUiOverlayStyle.light,
          actionsIconTheme: IconThemeData(color: Colors.white),
          // titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
          titleTextStyle: TextStyle(fontFamily: 'AmpleSoft', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 22),
          backgroundColor: primaryColor,foregroundColor: Colors.white
      );
    }
    // getLightDialogTheme() {
    //   return const DialogTheme(titleTextStyle: TextStyle(fontFamily: 'Myriad', fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20));
    // }
    getLightTextButtonTheme() {
      return TextButtonThemeData( style: TextButton.styleFrom(foregroundColor: primaryVariantColor, textStyle: const TextStyle(fontFamily: 'MadeTommy', fontWeight: FontWeight.bold, fontSize: 16)  ) );
    }
    getLightTextTheme() {
      // return GoogleFonts.rubikTextTheme (Typography.blackMountainView);
      return const TextTheme(
        titleLarge: TextStyle(
          fontFamily: 'AmpleSoft',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: secondaryColor,
        ),
        titleMedium: TextStyle(
          fontFamily: 'AmpleSoft',
          fontSize: 18,
          color: Colors.black,
        ),
        titleSmall: TextStyle(
          fontFamily: 'AmpleSoft',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.black45,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'AmpleSoft',
          fontSize: 18,
          color: Colors.black,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'AmpleSoft',
          fontSize: 15,
          color: Colors.black,
        ),
        bodySmall: TextStyle(
          fontFamily: 'AmpleSoft',
          fontSize: 12,
          color: Colors.black,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'AmpleSoft',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: secondaryColor,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'AmpleSoft',
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: secondaryColor,
        ),
      );
    }

    return ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: primaryColor,
        brightness: Brightness.light,
        secondary: secondaryColor,
        error: errorColor,
        tertiary: primaryVariantColor
    ),
        useMaterial3: true,
        appBarTheme: getLightAppBarTheme(),
        textTheme: getLightTextTheme(),
        filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom( shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)) , padding: const EdgeInsets.all(4.0), backgroundColor: secondaryColor, foregroundColor: Colors.white))
      // elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom( padding: const EdgeInsets.all(6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)) ,  backgroundColor: secondaryColor, foregroundColor: Colors.white ) ) ,
    );

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

  @override
  ThemeData getDarkTheme() {
    const primaryColor = Color(0xffCBDB2A);
    const secondaryColor = Color(0xffAFAFA9);
    const primaryVariantColor = Color(0xff0D0D0D);
    const errorColor = Color(0xffb00020);
    getDarkAppBarTheme() {
      return AppBarTheme(iconTheme: const IconThemeData(color: Colors.white),
          actionsIconTheme: const IconThemeData(color: Colors.white),
          // titleTextStyle: const TextStyle(fontFamily: 'Myriad', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 22),
          backgroundColor: primaryColor.darken(10),
          foregroundColor: Colors.white
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
      // return GoogleFonts.rubikTextTheme(Typography.whiteMountainView);
      return const TextTheme(
        titleLarge: TextStyle(
          fontFamily: 'AmpleSoft',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontFamily: 'AmpleSoft',
          fontSize: 18,
          color: Colors.white,
        ),
        titleSmall: TextStyle(
          fontFamily: 'AmpleSoft',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white60,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'AmpleSoft',
          fontSize: 18,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'AmpleSoft',
          fontSize: 14,
          color: Colors.white,
        ),
        bodySmall: TextStyle(
          fontFamily: 'AmpleSoft',
          fontSize: 12,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'AmpleSoft',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: secondaryColor,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'AmpleSoft',
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      );
    }

    return ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: primaryColor,
        brightness: Brightness.dark,
        secondary: secondaryColor,
        error: errorColor,
        tertiary: primaryColor
    ),
        useMaterial3: true,
        appBarTheme: getDarkAppBarTheme(),
        textTheme: getDarkTextTheme(),
        filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom( shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)) , padding: const EdgeInsets.all(4.0), backgroundColor: secondaryColor, foregroundColor: Colors.white))
    );

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
        dividerColor: Colors.white30,
        primaryColorDark: Colors.white70,
        iconTheme: const IconThemeData(color: primaryColor),
        elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom( padding: const EdgeInsets.all(6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)), backgroundColor: secondaryColor, foregroundColor: Colors.white ) ),
        textTheme:  getDarkTextTheme(),
        appBarTheme: getDarkAppBarTheme()
    );
  }



}