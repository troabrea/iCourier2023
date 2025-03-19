import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../appinfo.dart';

class EcopaqAppInfo implements AppInfo {

  @override
  String defaultLocale = 'es';
  @override
  String additionalLocale = '';
  @override
  String currencyCode = 'RD\$';

  @override
  int defaultTab = 2;

  @override
  String get brandLogoImage => "images/ecopaq/brand_logo.png";

  @override
  String get brandLogoImageDark => "images/ecopaq/brand_logo.png";

  @override
  String get centerIconImage => "images/ecopaq/icon.png";

  @override
  String get androidAnalyticsAppId => "96fe39c3-ac76-4913-b06d-04635576f280";

  @override
  String get iphoneAnalyticsAppId => "063e8c59-2b15-448e-98b6-60d670a51af7";

  @override
  String get companyId => "b04c3785-d9a5-4bb9-9bf5-f828e091ec79";

  @override
  String get metricsPrefixKey => "ECOPAQ";

  @override
  String get pushChannelTopic => "ECOPAQ";

  @override
  double get centerIconSize => 60;
  @override
  double get centerInactiveIconSize => 40;

  @override
  ThemeData getLightTheme() {
    const primaryColor = Color(0xff009540);
    const secondaryColor = Color(0xff009540);
    const primaryVariantColor = Color(0xfffdd73f);
    const errorColor = Color(0xffb00020);

    getLightAppBarTheme() {
      return  AppBarTheme(iconTheme: const IconThemeData(color: Colors.white),
          systemOverlayStyle: SystemUiOverlayStyle.light,
          actionsIconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: GoogleFonts.montserrat( fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
          // titleTextStyle: TextStyle(fontFamily: 'Myriad', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 22),
          backgroundColor: primaryColor,foregroundColor: Colors.white
      );
    }
    // getLightDialogTheme() {
    //   return const DialogTheme(titleTextStyle: TextStyle(fontFamily: 'Myriad', fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20));
    // }
    getLightTextButtonTheme() {
      return TextButtonThemeData( style: TextButton.styleFrom(foregroundColor: primaryVariantColor, textStyle: const TextStyle(fontFamily: 'Myriad', fontWeight: FontWeight.bold, fontSize: 16)  ) );
    }
    getLightTextTheme() {
      return GoogleFonts.montserratTextTheme(Typography.blackMountainView);
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

  }

  @override
  ThemeData getDarkTheme() {
    const primaryColor = Color(0xff009540);
    const secondaryColor = Color(0xff009540);
    const primaryVariantColor = Color(0xfffdd73f);
    const errorColor = Color(0xffb00020);
    getDarkAppBarTheme() {
      return AppBarTheme(iconTheme: const IconThemeData(color: Colors.white),
          actionsIconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: GoogleFonts.montserrat( fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
          backgroundColor: primaryColor.darken(10),
          foregroundColor: const Color(0xff8CC9F8)
      );
    }

    getDarkTextTheme() {
      return GoogleFonts.montserratTextTheme(Typography.whiteMountainView);
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

  }



}