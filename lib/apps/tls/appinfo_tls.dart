import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../appinfo.dart';

class TlsAppInfo implements AppInfo {

  @override
  int defaultTab = 2;

  @override
  String get brandLogoImage => "images/tls/brand_logo.png";

  @override
  String get brandLogoImageDark => "images/tls/brand_logo.png";

  @override
  String get centerIconImage => "images/tls/ic_launcher_foreground.png";

  @override
  String get androidAnalyticsAppId => "1e5c3d46-2323-4906-aa0b-6377fa84701d";

  @override
  String get iphoneAnalyticsAppId => "d865fffd-b98e-418f-a13f-f380ca7a292a";

  @override
  String get companyId => "a2695534-9b0d-424f-949c-bb9d5cb453ce";

  @override
  String get metricsPrefixKey => "TLS";

  @override
  String get pushChannelTopic => "TLS";

  @override
  double get centerIconSize => 120;
  @override
  double get centerInactiveIconSize => 60;

  @override
  ThemeData getLightTheme() {
    const primaryColor = Color(0xff1c6fb7);
    const secondaryColor = Color(0xff2f5069);
    const primaryVariantColor = Color(0xff1c6fb7);
    const errorColor = Color(0xffb00020);

    getLightAppBarTheme() {
      return const AppBarTheme(iconTheme: IconThemeData(color: Colors.white),
          actionsIconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          backgroundColor: primaryColor,foregroundColor: Colors.white
      );
    }
    getLightTextButtonTheme() {
      return TextButtonThemeData( style: TextButton.styleFrom(foregroundColor: primaryVariantColor, textStyle: const TextStyle(fontFamily: 'Myriad', fontWeight: FontWeight.bold, fontSize: 16)  ) );
    }
    getLightTextTheme() {
      return GoogleFonts.rubikTextTheme (Typography.blackMountainView);
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
    const primaryColor = Color(0xff1c6fb7);
    const secondaryColor = Color(0xff5b9bcb);
    // const primaryVariantColor = Color(0xff005580);
    const errorColor = Color(0xffb00020);
    getDarkAppBarTheme() {
      return AppBarTheme(iconTheme: const IconThemeData(color: Colors.white),
          actionsIconTheme: const IconThemeData(color: Colors.white),
          // titleTextStyle: const TextStyle(fontFamily: 'Myriad', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 22),
          backgroundColor: primaryColor.darken(10),
          foregroundColor: Colors.white
      );
    }
    getDarkTextTheme() {
      return GoogleFonts.rubikTextTheme(Typography.whiteMountainView);
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