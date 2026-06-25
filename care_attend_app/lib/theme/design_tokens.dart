import 'package:flutter/material.dart';

/// Design tokens for the CareAttend app.
///
/// Single source of truth for spacing, radius, elevation, motion, and semantic
/// colour. Screens and widgets reference these instead of hard-coded numbers so
/// the visual system stays consistent ("world-class" comes from consistency, not
/// one-off flourishes). Colours keep the NHS Design System palette.
class AppSpace {
  AppSpace._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  static const EdgeInsets screen = EdgeInsets.all(lg);
  static const EdgeInsets card = EdgeInsets.all(lg);
}

class AppRadius {
  AppRadius._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const Radius rSm = Radius.circular(sm);
  static const Radius rMd = Radius.circular(md);
  static const Radius rLg = Radius.circular(lg);
}

class AppMotion {
  AppMotion._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Curve curve = Curves.easeOutCubic;
}

/// Semantic colour tokens. NHS palette underneath, exposed by role so widgets
/// ask for meaning ("risk high") not a raw hex.
class AppColors {
  AppColors._();
  // NHS brand
  static const Color brand = Color(0xFF003087); // NHS Blue
  static const Color brandDark = Color(0xFF002060);
  static const Color brandAccent = Color(0xFF41B6E6); // NHS Light Blue

  // Neutrals
  static const Color paleGrey = Color(0xFFF0F4F5);
  static const Color grey = Color(0xFFAEB7BD);
  static const Color darkGrey = Color(0xFF425563);
  static const Color ink = Color(0xFF231F20);

  // Risk / status (AA+ contrast on white)
  static const Color riskHigh = Color(0xFFD5281B); // darkened for AAA-leaning
  static const Color riskMedium = Color(0xFF8A6100); // amber text-safe
  static const Color riskLow = Color(0xFF007F3B);
  static const Color riskHighBg = Color(0xFFFFEBEE);
  static const Color riskMediumBg = Color(0xFFFFF8E1);
  static const Color riskLowBg = Color(0xFFE8F5E9);

  static const Color success = riskLow;
  static const Color warning = Color(0xFFB8860B);
  static const Color danger = riskHigh;

  // Dark surface set (high-contrast slate)
  static const Color darkBg = Color(0xFF12182B);
  static const Color darkSurface = Color(0xFF1B2540);
  static const Color darkSurfaceAlt = Color(0xFF243154);

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

  static Color riskBg(String tier) {
    switch (tier.toLowerCase()) {
      case 'high':
        return riskHighBg;
      case 'medium':
        return riskMediumBg;
      default:
        return riskLowBg;
    }
  }
}

/// Soft, layered elevation shadows (one tier used app-wide for calm depth).
class AppShadow {
  AppShadow._();
  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];
}
