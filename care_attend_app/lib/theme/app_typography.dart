import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography for CareAttend.
///
/// Lexend for headings — designed to improve reading proficiency, a deliberate
/// choice for a vulnerable/low-literacy patient audience. Inter for body/UI:
/// high legibility at small sizes. Both bundled via google_fonts.
///
/// For Urdu (RTL), Material falls back to a Nastaliq/Arabic script font supplied
/// per-locale in the theme; this scale governs sizes/weights only.
class AppType {
  AppType._();

  static TextTheme textTheme(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? Typography.material2021().white
        : Typography.material2021().black;

    final heading = GoogleFonts.lexendTextTheme(base);
    final body = GoogleFonts.interTextTheme(base);

    final merged = base.copyWith(
      displayLarge: heading.displayLarge?.copyWith(fontWeight: FontWeight.w700),
      displayMedium:
          heading.displayMedium?.copyWith(fontWeight: FontWeight.w700),
      displaySmall: heading.displaySmall?.copyWith(fontWeight: FontWeight.w700),
      headlineLarge:
          heading.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
      headlineMedium:
          heading.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
      headlineSmall:
          heading.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: heading.titleLarge
          ?.copyWith(fontWeight: FontWeight.w700, fontSize: 22),
      titleMedium: heading.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: heading.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: body.bodyLarge?.copyWith(fontSize: 16, height: 1.5),
      bodyMedium: body.bodyMedium?.copyWith(fontSize: 14, height: 1.45),
      bodySmall: body.bodySmall?.copyWith(fontSize: 12, height: 1.4),
      labelLarge: body.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      labelMedium: body.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      labelSmall: body.labelSmall?.copyWith(fontWeight: FontWeight.w600),
    );
    // Latin fonts (Lexend/Inter) lack Arabic glyphs; chain the bundled Noto
    // Sans Arabic as a fallback so Urdu renders without CanvasKit hunting a
    // remote Noto font.
    return _withFallback(merged, const ['NotoSansArabic']);
  }

  static TextTheme _withFallback(TextTheme t, List<String> fb) {
    TextStyle? f(TextStyle? s) => s?.copyWith(fontFamilyFallback: fb);
    return TextTheme(
      displayLarge: f(t.displayLarge),
      displayMedium: f(t.displayMedium),
      displaySmall: f(t.displaySmall),
      headlineLarge: f(t.headlineLarge),
      headlineMedium: f(t.headlineMedium),
      headlineSmall: f(t.headlineSmall),
      titleLarge: f(t.titleLarge),
      titleMedium: f(t.titleMedium),
      titleSmall: f(t.titleSmall),
      bodyLarge: f(t.bodyLarge),
      bodyMedium: f(t.bodyMedium),
      bodySmall: f(t.bodySmall),
      labelLarge: f(t.labelLarge),
      labelMedium: f(t.labelMedium),
      labelSmall: f(t.labelSmall),
    );
  }
}
