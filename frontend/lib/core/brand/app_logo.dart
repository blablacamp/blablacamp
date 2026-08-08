import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// The BlaBlaCamp mountain mark. Tint via [color]; sizes to [size] (square).
class AppLogoMark extends StatelessWidget {
  const AppLogoMark({super.key, this.size = 32, this.color = AppColors.accent});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/brand/logo_mark.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

/// "BlaBla" (word color) + "Camp" (accent) wordmark, with optional subtitle.
class AppWordmark extends StatelessWidget {
  const AppWordmark({
    super.key,
    this.size = 28,
    this.showSubtitle = false,
    this.onDark = false,
    this.center = false,
  });

  final double size;
  final bool showSubtitle;
  final bool onDark;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final wordColor = onDark ? AppColors.cream : AppColors.textPrimary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        RichText(
          textAlign: center ? TextAlign.center : TextAlign.start,
          text: TextSpan(
            style: GoogleFonts.unbounded(
              fontSize: size,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
            children: [
              TextSpan(text: 'BlaBla', style: TextStyle(color: wordColor)),
              const TextSpan(
                  text: 'Camp', style: TextStyle(color: AppColors.accent)),
            ],
          ),
        ),
        if (showSubtitle) ...[
          SizedBox(height: size * 0.14),
          Text('СВОЇ ЛЮДИ — СВОЇ ГОРИ',
              style: GoogleFonts.ibmPlexMono(
                fontSize: size * 0.32,
                letterSpacing: 1.5,
                color:
                    onDark ? AppColors.mutedOnDark : AppColors.textSecondary,
              )),
        ],
      ],
    );
  }
}

/// Full horizontal lockup: mountain mark + wordmark + optional subtitle.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 28,
    this.showSubtitle = false,
    this.onDark = false,
  });

  final double size;
  final bool showSubtitle;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogoMark(size: size * 1.5, color: AppColors.accent),
        SizedBox(width: size * 0.4),
        AppWordmark(
            size: size, showSubtitle: showSubtitle, onDark: onDark),
      ],
    );
  }
}
