import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../../features/hikes/data/models/profile_ref.dart';

/// Circular avatar: network image when available, otherwise initials on a
/// muted disc. Used in feed meta rows, guide cards and avatar stacks.
class AvatarCircle extends StatelessWidget {
  const AvatarCircle({super.key, required this.profile, this.size = 24});

  final ProfileRef profile;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hasImage = profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: AppColors.divider,
        shape: BoxShape.circle,
      ),
      child: hasImage
          ? Image.network(
              profile.avatarUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _initials(),
            )
          : _initials(),
    );
  }

  Widget _initials() => Center(
        child: Text(
          profile.initials,
          style: GoogleFonts.manrope(
            fontSize: size * 0.4,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      );
}
