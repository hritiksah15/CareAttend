import 'package:flutter/material.dart';

class NHSTheme {
  static const Color blue = Color(0xFF003087);
  static const Color darkBlue = Color(0xFF002060);
  static const Color lightBlue = Color(0xFF41B6E6);
  static const Color white = Color(0xFFFFFFFF);
  static const Color paleGrey = Color(0xFFF0F4F5);
  static const Color grey = Color(0xFFAEB7BD);
  static const Color darkGrey = Color(0xFF425563);
  static const Color black = Color(0xFF231F20);

  static const Color riskLow = Color(0xFF007F3B);
  static const Color riskMedium = Color(0xFFFFB81C);
  static const Color riskHigh = Color(0xFFDA291C);
  static const Color riskLowBg = Color(0xFFE8F5E9);
  static const Color riskMediumBg = Color(0xFFFFF8E1);
  static const Color riskHighBg = Color(0xFFFFEBEE);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        primaryColor: blue,
        scaffoldBackgroundColor: paleGrey,
        fontFamily: 'Arial',
        colorScheme: const ColorScheme.light(
          primary: blue,
          secondary: lightBlue,
          error: riskHigh,
          surface: white,
        ),
        // Material 3 bottom navigation — the app's signature chrome,
        // visually distinct from the website's top tab bar.
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: white,
          indicatorColor: lightBlue.withValues(alpha: 0.22),
          elevation: 3,
          height: 68,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              size: 26,
              color: selected ? blue : darkGrey,
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontFamily: 'Arial',
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? blue : darkGrey,
            );
          }),
        ),
        cardTheme: CardThemeData(
          color: white,
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: blue,
          foregroundColor: white,
          elevation: 2,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Arial',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: blue,
            foregroundColor: white,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: grey, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: blue, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      );

  // Dark mode — mirrors the website's high-contrast slate palette.
  static const Color darkBg = Color(0xFF1A1A2E);
  static const Color darkSurface = Color(0xFF16213E);

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: lightBlue,
        scaffoldBackgroundColor: darkBg,
        fontFamily: 'Arial',
        colorScheme: const ColorScheme.dark(
          primary: lightBlue,
          secondary: lightBlue,
          surface: darkSurface,
          error: riskHigh,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: darkSurface,
          foregroundColor: white,
          elevation: 2,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Arial',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: white,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: darkSurface,
          indicatorColor: lightBlue.withValues(alpha: 0.30),
          elevation: 3,
          height: 68,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        ),
        cardTheme: CardThemeData(
          color: darkSurface,
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: lightBlue,
            foregroundColor: black,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );

  static Color riskColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'high':
        return riskHigh;
      case 'medium':
        return riskMedium;
      default:
        return riskLow;
    }
  }

  static Color riskBgColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'high':
        return riskHighBg;
      case 'medium':
        return riskMediumBg;
      default:
        return riskLowBg;
    }
  }

  static String ageGroup(int age) {
    if (age < 18) return 'Under 18';
    if (age < 65) return '18-64';
    if (age < 75) return '65-74';
    if (age < 85) return '75-84';
    return '85+';
  }
}
