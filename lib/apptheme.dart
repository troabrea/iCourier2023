import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

ThemeData getLightTheme()
{

  Color primaryColor = const Color(0xfff7d701);

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

ThemeData getDarkTheme()
{
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

TextTheme getLightTextTheme() {
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

TextTheme getDarkTextTheme() {
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

ThemeData getAppTheme() {
  ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: const Color.fromRGBO(247, 215, 1, 1),
      brightness: Brightness.light,
      primary: const Color.fromRGBO(247, 215, 1, 1),
      secondary: Colors.black,
      background: Colors.white,
      tertiary: Colors.black45);

  var themeData = ThemeData.from(
      colorScheme: colorScheme,
      useMaterial3: false,
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          color: Colors.black,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.black45,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          color: Colors.black,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ));

  themeData = themeData.copyWith(
      appBarTheme: const AppBarTheme(
          color: Color.fromRGBO(247, 215, 1, 1),
          foregroundColor: Colors.black,
          toolbarTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          )));

  return themeData;
}