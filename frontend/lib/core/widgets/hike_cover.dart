import 'package:flutter/material.dart';

import '../../features/hikes/data/models/hike.dart';

/// A hike's cover photo. Uses the network `coverUrl` when set, otherwise a
/// bundled landscape fallback so lists always look intentional.
class HikeCover extends StatelessWidget {
  const HikeCover({
    super.key,
    required this.hike,
    this.borderRadius,
    this.width,
    this.height,
  });

  final Hike hike;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;

  static const _fallbacks = [
    'assets/images/cover_fallback.jpg',
    'assets/images/cover_fallback_2.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    final fallback = _fallbacks[hike.id.hashCode.abs() % _fallbacks.length];
    final hasUrl = hike.coverUrl != null && hike.coverUrl!.isNotEmpty;
    final image = hasUrl
        ? Image.network(
            hike.coverUrl!,
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                Image.asset(fallback, width: width, height: height, fit: BoxFit.cover),
          )
        : Image.asset(fallback, width: width, height: height, fit: BoxFit.cover);

    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }
}
