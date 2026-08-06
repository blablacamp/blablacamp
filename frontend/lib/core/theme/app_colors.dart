import 'package:flutter/material.dart';

/// Design tokens (colors) pulled from the Figma "Blablacamp" file.
/// Keep this the single source of truth — screens must not hardcode hex.
abstract final class AppColors {
  // Dark base
  static const ink = Color(0xFF121719); // page background on dark screens
  static const inkSoft = Color(0xFF1B2225); // slightly raised dark surface

  // Cream / light
  static const cream = Color(0xFFFCFAF6); // text on dark, light page bg
  static const surface = Color(0xFFF3F1EB); // cards / inputs on light

  // Accent
  static const accent = Color(0xFFC94D32); // primary CTA (terracotta)
  static const accentPressed = Color(0xFFB2402A);

  // Text
  static const textPrimary = Color(0xFF24292A); // headings on light
  static const textSecondary = Color(0xFF425158); // body on light
  static const mutedOnDark = Color(0xFFC5D2D1); // secondary text on dark

  // Utility
  static const divider = Color(0xFFE2DED4);
  static const success = Color(0xFF3F7D5A);
  static const warning = Color(0xFFD08A2C);
}
