import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/hikes/data/models/profile_ref.dart';
import '../theme/app_colors.dart';
import 'avatar_circle.dart';

/// "Who's already going" — approved participant count + avatars/names.
/// [max] is the hike capacity; [organizer] is shown first with a badge.
class HikeParticipants extends StatelessWidget {
  const HikeParticipants({
    super.key,
    required this.members,
    required this.max,
    required this.organizer,
  });

  final List<ProfileRef> members;
  final int max;
  final ProfileRef organizer;

  @override
  Widget build(BuildContext context) {
    // Merge organizer + members, organizer first, de-duplicated by id.
    final seen = <String>{};
    final people = <(ProfileRef, bool)>[]; // (profile, isOrganizer)
    if (organizer.id.isNotEmpty && seen.add(organizer.id)) {
      people.add((organizer, true));
    }
    for (final m in members) {
      if (seen.add(m.id)) people.add((m, false));
    }
    final going = people.length;
    final spotsLeft = (max - going).clamp(0, max);
    final full = spotsLeft <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('$going з $max',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                )),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: full ? const Color(0x1AC94D32) : const Color(0x1A47725B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                  full ? 'Місць немає' : 'ще $spotsLeft ${_spotWord(spotsLeft)}',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: full ? AppColors.accent : const Color(0xFF47725B),
                  )),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [for (final p in people) _Person(profile: p.$1, isOrganizer: p.$2)],
        ),
      ],
    );
  }

  String _spotWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'місце';
    if ([2, 3, 4].contains(n % 10) && !(n % 100 >= 12 && n % 100 <= 14)) {
      return 'місця';
    }
    return 'місць';
  }
}

class _Person extends StatelessWidget {
  const _Person({required this.profile, required this.isOrganizer});
  final ProfileRef profile;
  final bool isOrganizer;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: InkWell(
        onTap: () => context.push('/user/${profile.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AvatarCircle(profile: profile, size: 48),
              if (isOrganizer)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star,
                        size: 12, color: AppColors.cream),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            profile.displayName.split(' ').first,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
        ),
      ),
    );
  }
}
