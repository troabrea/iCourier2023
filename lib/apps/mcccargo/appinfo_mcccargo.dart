import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../appinfo.dart';

class MccCargoAppInfo implements AppInfo {

  @override
  String defaultLocale = 'es';
  @override
  String additionalLocale = '';
  @override
  String currencyCode = 'RD\$';

  @override
  int defaultTab = 2;

  @override
  String get brandLogoImage => "images/mcccargo/brand_logo.png";

  @override
  String get brandLogoImageDark => "images/mcccargo/brand_logo.png";

  @override
  String get centerIconImage => "images/mcccargo/icon.png";

  @override
  String get androidAnalyticsAppId => "208dfe36-b56e-47ce-a721-89b3d037c594";

  @override
  String get iphoneAnalyticsAppId => "bf0f6706-0f71-4789-8a8d-b064d6afc228";

  @override
  String get companyId => "4d57b3bd-f19a-4985-b845-0f3457b4cc0c";

  @override
  String get metricsPrefixKey => "MCCCARGO";

  @override
  String get pushChannelTopic => "MCCCARGO";

  @override
  double get centerIconSize => 60;
  @override
  double get centerInactiveIconSize => 40;

  @override
  ThemeData getLightTheme() {
    const primaryColor = Color(0xff213263);
    const secondaryColor = Color(0xff279AF1);
    const primaryVariantColor = Color(0xff4766C2);
    const errorColor = Color(0xffb00020);

    getLightAppBarTheme() {
      return  AppBarTheme(iconTheme: const IconThemeData(color: Colors.white),
          systemOverlayStyle: SystemUiOverlayStyle.light,
          actionsIconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: GoogleFonts.unbounded( fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
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
      return GoogleFonts.outfitTextTheme(Typography.blackMountainView);
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
    const primaryColor = Color(0xff213263);
    const secondaryColor = Color(0xff279AF1);
    const primaryVariantColor = Color(0xff1F3A68);
    const errorColor = Color(0xffb00020);
    getDarkAppBarTheme() {
      return AppBarTheme(iconTheme: const IconThemeData(color: Colors.white),
          actionsIconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: GoogleFonts.unbounded( fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
          backgroundColor: primaryColor.darken(10),
          foregroundColor: const Color(0xff8CC9F8)
      );
    }

    getDarkTextTheme() {
      return GoogleFonts.outfitTextTheme(Typography.whiteMountainView);
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