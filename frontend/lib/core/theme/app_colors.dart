import 'package:flutter/material.dart';

/// Design tokens (colors) pulled from the Figma "Blablacamp" file.
/// Keep this the single source of truth — screens must not hardcode hex.
abstract final class AppColors {
  // Dark base
  static const ink = Color(0xFF121719); // page background on dark screens
  static const inkSoft = Color(0xFF1B2225); // slightly raised dark surface

  // Cream / light (warmed a touch for a cozier feel)
  static const cream = Color(0xFFFCFAF5); // text on dark, light page bg
  static const surface = Color(0xFFF4F0E8); // cards / inputs on light

  // Accent
  static const accent = Color(0xFFC94D32); // primary CTA (terracotta)
  static const accentPressed = Color(0xFFB2402A);
  static const accentSoft = Color(0xFFE8642C); // lighter terracotta (gradients)
  static const honey = Color(0xFFD9A441); // warm secondary accent (Galician)

  // Text
  static const textPrimary = Color(0xFF24292A); // headings on light
  static const textSecondary = Color(0xFF425158); // body on light
  static const mutedOnDark = Color(0xFFC5D2D1); // secondary text on dark

  // Utility
  static const divider = Color(0xFFE7E1D4);
  static const success = Color(0xFF3F7D5A);
  static const warning = Color(0xFFD08A2C);

  /// Smooth terracotta gradient for primary CTAs.
  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentSoft, accent],
  );

  /// Soft, warm card shadow — diffuse and gentle ("смузі").
  static const softShadow = <BoxShadow>[
    BoxShadow(color: Color(0x14332017), blurRadius: 24, offset: Offset(0, 10)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
  ];
}
