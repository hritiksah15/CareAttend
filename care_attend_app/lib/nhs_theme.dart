import 'package:flutter/material.dart';
import 'theme/design_tokens.dart';
import 'theme/app_typography.dart';

/// CareAttend theme. Colour constants preserved for backward compatibility with
/// existing screens; the [theme]/[darkTheme] getters are rebuilt on the design
/// tokens ([AppSpace]/[AppRadius]/[AppColors]) and real typography ([AppType]).
class NHSTheme {
  static const Color blue = AppColors.brand;
  static const Color darkBlue = AppColors.brandDark;
  static const Color lightBlue = AppColors.brandAccent;
  static const Color white = Color(0xFFFFFFFF);
  static const Color paleGrey = AppColors.paleGrey;
  static const Color grey = AppColors.grey;
  static const Color darkGrey = AppColors.darkGrey;
  static const Color black = AppColors.ink;

  static const Color riskLow = AppColors.riskLow;
  static const Color riskMedium = AppColors.riskMedium;
  static const Color riskHigh = AppColors.riskHigh;
  static const Color riskLowBg = AppColors.riskLowBg;
  static const Color riskMediumBg = AppColors.riskMediumBg;
  static const Color riskHighBg = AppColors.riskHighBg;

  static const Color darkBg = AppColors.darkBg;
  static const Color darkSurface = AppColors.darkSurface;

  static ThemeData get theme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    // Full surface ladder + text roles set explicitly so every Material 3
    // component (Card, Dialog, Menu, BottomSheet) inherits an on-palette,
    // visibly-separated surface instead of falling back to M3 defaults.
    final scheme = dark
        ? const ColorScheme.dark(
            primary: lightBlue,
            onPrimary: AppColors.ink,
            secondary: lightBlue,
            onSecondary: AppColors.ink,
            surface: AppColors.darkSurface,
            onSurface: Color(0xFFE8EEF3),
            onSurfaceVariant: AppColors.darkOnSurfaceVariant,
            surfaceContainerLowest: AppColors.darkBg,
            surfaceContainerLow: AppColors.darkSurface,
            surfaceContainer: AppColors.darkSurface,
            surfaceContainerHigh: AppColors.darkSurfaceAlt,
            surfaceContainerHighest: AppColors.darkSurfaceAlt,
            outline: AppColors.darkOutline,
            outlineVariant: AppColors.darkOutline,
            error: riskHigh,
          )
        : const ColorScheme.light(
            primary: blue,
            secondary: lightBlue,
            surface: white,
            onSurface: AppColors.ink,
            onSurfaceVariant: AppColors.darkGrey,
            surfaceContainerLowest: white,
            surfaceContainerLow: paleGrey,
            surfaceContainerHigh: white,
            surfaceContainerHighest: white,
            outline: AppColors.grey,
            error: riskHigh,
          );

    final textTheme = AppType.textTheme(brightness);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? AppColors.darkBg : AppColors.paleGrey,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? AppColors.darkSurface : blue,
        foregroundColor: white,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: white, fontSize: 20),
      ),
      cardTheme: CardThemeData(
        color: dark ? AppColors.darkSurface : white,
        elevation: 0,
        // In dark mode the surface/scaffold lightness gap is subtle, so add a
        // hairline outline border to make every card edge unambiguous.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: dark
              ? const BorderSide(color: AppColors.darkOutline, width: 1)
              : BorderSide.none,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dark ? AppColors.darkSurface : white,
        indicatorColor: lightBlue.withValues(alpha: dark ? 0.30 : 0.20),
        elevation: 3,
        height: 70,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          return IconThemeData(size: 26, color: sel ? (dark ? lightBlue : blue) : grey);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            fontSize: 12,
            color: sel ? (dark ? lightBlue : blue) : darkGrey,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: dark ? lightBlue : blue,
          foregroundColor: dark ? AppColors.ink : white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 16, letterSpacing: 0.3),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        // Recessed fill: darker than both card and dialog surfaces so inputs
        // stay visible whether placed on a card or inside a raised dialog.
        fillColor: dark ? AppColors.darkBg : white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: dark ? AppColors.darkOutline : grey, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: dark ? AppColors.darkOutline : grey, width: 1.5),
        ),
        labelStyle: TextStyle(color: dark ? AppColors.darkOnSurfaceVariant : darkGrey),
        hintStyle: TextStyle(color: dark ? AppColors.darkOnSurfaceVariant : grey),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: dark ? lightBlue : blue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: dark ? AppColors.darkSurfaceAlt : AppColors.paleGrey,
        labelStyle: textTheme.bodySmall,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        side: BorderSide.none,
      ),
      dialogTheme: DialogThemeData(
        // Raised surface so dialogs clearly float above the dimmed content.
        backgroundColor: dark ? AppColors.darkSurfaceAlt : white,
        surfaceTintColor: Colors.transparent,
        elevation: dark ? 0 : 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: dark
              ? const BorderSide(color: AppColors.darkOutline, width: 1)
              : BorderSide.none,
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(
              dark ? AppColors.darkSurfaceAlt : white),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: dark ? AppColors.darkSurfaceAlt : white,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: dark ? AppColors.darkSurfaceAlt : white,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      dividerTheme: const DividerThemeData(space: 1, thickness: 1),
    );
  }

  static Color riskColor(String tier) => AppColors.riskColor(tier);
  static Color riskBgColor(String tier) => AppColors.riskBg(tier);

  static String ageGroup(int age) {
    if (age < 18) return 'Under 18';
    if (age < 65) return '18-64';
    if (age < 75) return '65-74';
    if (age < 85) return '75-84';
    return '85+';
  }
}
