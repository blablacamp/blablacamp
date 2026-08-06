import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_shapes.dart';
import '../utils/date_format.dart';
import '../../features/hikes/data/models/hike.dart';
import 'hike_cover.dart';

/// Compact hike row: cover thumb + title + meta line, with an optional trailing
/// widget (e.g. a favorite heart or an unread badge). Reused across tabs.
class HikeListTile extends StatelessWidget {
  const HikeListTile({
    super.key,
    required this.hike,
    this.onTap,
    this.trailing,
    this.subtitle,
  });

  final Hike hike;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final meta = subtitle ??
        '${formatDateRange(hike.startDate, hike.endDate)} · ${hike.region ?? ''} · ${hike.type.label}';
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            HikeCover(
              hike: hike,
              width: 64,
              height: 64,
              borderRadius: AppShapes.leafOf(12, 4),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hike.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      )),
                  const SizedBox(height: 4),
                  Text(meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 12,
                        color: const Color(0xFF52727D),
                      )),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}
