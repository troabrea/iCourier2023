import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../appinfo.dart';

class InboxAppInfo implements AppInfo {

  @override
  String defaultLocale = 'es';
  @override
  String additionalLocale = '';
  @override
  String currencyCode = 'RD\$';

  @override
  int defaultTab = 2;

  @override
  String get brandLogoImage => "images/inbox/brand_logo.png";

  @override
  String get brandLogoImageDark => "images/inbox/brand_logo.png";

  @override
  String get centerIconImage => "images/inbox/icon.png";

  @override
  String get androidAnalyticsAppId => "a43fa9bb-bb66-4bc4-b6f9-bbbe57a99a7f";

  @override
  String get iphoneAnalyticsAppId => "53733f12-2741-49dc-92fa-69d1b0eed89f";

  @override
  String get companyId => "46ead561-5beb-4466-8112-803fa3e3e1eb";

  @override
  String get metricsPrefixKey => "INBOX";

  @override
  String get pushChannelTopic => "INBOX";

  @override
  double get centerIconSize => 60;
  @override
  double get centerInactiveIconSize => 40;

  @override
  ThemeData getLightTheme() {
    const primaryColor = Color(0xff28C3F3);
    const secondaryColor = Color(0xff28C3F3);
    const primaryVariantColor = Color(0xff62737D);
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
      return GoogleFonts.latoTextTheme(Typography.blackMountainView);
      // return const TextTheme(
      //   titleLarge: TextStyle(
      //     fontFamily: 'ComicSans',
      //     fontSize: 20,
      //     fontWeight: FontWeight.w700,
      //     color: secondaryColor,
      //   ),
      //   titleMedium: TextStyle(
      //     fontFamily: 'ComicSans',
      //     fontSize: 18,
      //     color: Colors.black,
      //   ),
      //   titleSmall: TextStyle(
      //     fontFamily: 'ComicSans',
      //     fontSize: 14,
      //     fontWeight: FontWeight.w700,
      //     color: Colors.black45,
      //   ),
      //   bodyLarge: TextStyle(
      //     fontFamily: 'ComicSans',
      //     fontSize: 18,
      //     color: Colors.black,
      //   ),
      //   bodyMedium: TextStyle(
      //     fontFamily: 'ComicSans',
      //     fontSize: 15,
      //     color: Colors.black,
      //   ),
      //   bodySmall: TextStyle(
      //     fontFamily: 'ComicSans',
      //     fontSize: 12,
      //     color: Colors.black,
      //   ),
      //   headlineMedium: TextStyle(
      //     fontFamily: 'ComicSans',
      //     fontSize: 18,
      //     fontWeight: FontWeight.w700,
      //     color: secondaryColor,
      //   ),
      //   headlineLarge: TextStyle(
      //     fontFamily: 'ComicSans',
      //     fontSize: 26,
      //     fontWeight: FontWeight.w700,
      //     color: secondaryColor,
      //   ),
      // );
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
        filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom( shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)) , padding: const EdgeInsets.all(4.0), backgroundColor: secondaryColor, foregroundColor: Colors.white))
      // elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom( padding: const EdgeInsets.all(6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)) ,  backgroundColor: secondaryColor, foregroundColor: Colors.white ) ) ,
    );

  }

  @override
  ThemeData getDarkTheme() {
    const primaryColor = Color(0xff28C3F3);
    const secondaryColor = Color(0xff28C3F3);
    const primaryVariantColor = Color(0xfff9f9f9);
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
      return GoogleFonts.latoTextTheme(Typography.whiteMountainView);
      // return const TextTheme(
      //   titleLarge: TextStyle(
      //     fontFamily: 'ComicSans',
      //     fontSize: 20,
      //     fontWeight: FontWeight.w700,
      //     color: Colors.white,
      //   ),
      //   titleMedium: TextStyle(
      //     fontFamily: 'ComicSans',
      //     fontSize: 18,
      //     color: Colors.white,
      //   ),
      //   titleSmall: TextStyle(
      //     fontFamily: 'ComicSans',
      //     fontSize: 16,
      //     fontWeight: FontWeight.w700,
      //     color: Colors.white60,
      //   ),
      //   bodyLarge: TextStyle(
      //     fontFamily: 'ComicSans',
      //     fontSize: 18,
      //     color: Colors.white,
      //   ),
      //   bodyMedium: TextStyle(
      //     fontFamily: 'ComicSans',
      //     fontSize: 14,
      //     color: Colors.white,
      //   ),
      //   bodySmall: TextStyle(
      //     fontFamily: 'ComicSans',
      //     fontSize: 12,
      //     color: Colors.white,
      //   ),
      //   headlineMedium: TextStyle(
      //     fontFamily: 'ComicSans',
      //     fontSize: 18,
      //     fontWeight: FontWeight.w700,
      //     color: secondaryColor,
      //   ),
      //   headlineLarge: TextStyle(
      //     fontFamily: 'ComicSans',
      //     fontSize: 26,
      //     fontWeight: FontWeight.w700,
      //     color: Colors.white,
      //   ),
      // );
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
        filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom( shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)) , padding: const EdgeInsets.all(4.0), backgroundColor: secondaryColor, foregroundColor: Colors.white))
    );

  }



}