import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Builds the app-wide [ThemeData].
/// Type system: Unbounded for display/headings, Manrope for everything else.
abstract final class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accent,
        onPrimary: AppColors.cream,
        secondary: AppColors.ink,
        onSecondary: AppColors.cream,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
    );

    final manrope = GoogleFonts.manropeTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: manrope.copyWith(
        displayLarge: GoogleFonts.unbounded(
          fontSize: 26,
          height: 34 / 26,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineSmall: GoogleFonts.unbounded(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.manrope(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 15,
          height: 22 / 15,
          color: AppColors.textSecondary,
        ),
        bodySmall: GoogleFonts.manrope(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
      splashFactory: InkRipple.splashFactory,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.cream,
        // No filled "pill" — the design uses colour + an active dot instead.
        indicatorColor: Colors.transparent,
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? AppColors.accent
                : AppColors.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColors.accent
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
