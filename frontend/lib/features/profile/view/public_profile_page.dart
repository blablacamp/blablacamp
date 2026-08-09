import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shapes.dart';
import '../../../core/web/widgets/web_chrome.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../../core/widgets/star_rating.dart';
import '../../hikes/data/hikes_repository.dart';
import '../../hikes/data/models/profile_ref.dart';
import '../../hikes/data/models/review.dart';

/// Public profile of any camper/guide — who they are + their reviews.
class PublicProfilePage extends StatefulWidget {
  const PublicProfilePage({super.key, required this.userId});
  final String userId;

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  HikesRepository get _repo => context.read<HikesRepository>();
  bool _loading = true;
  ({ProfileRef profile, String? bio, String role})? _data;
  ({double average, int count}) _rating = (average: 0, count: 0);
  List<Review> _reviews = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Load each piece independently so one failure never blocks the page.
    try {
      _data = await _repo.fetchProfile(widget.userId);
    } catch (_) {}
    try {
      _rating = await _repo.fetchUserRating(widget.userId);
    } catch (_) {}
    try {
      _reviews = await _repo.fetchReviews(widget.userId);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
        : _data == null
            ? Center(
                child: Text('Профіль не знайдено',
                    style: GoogleFonts.manrope(color: AppColors.textSecondary)))
            : _content();

    if (context.isDesktop) {
      return WebChrome(
        maxContentWidth: 760,
        child: body,
      );
    }
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(_data?.profile.displayName ?? 'Профіль',
            style: GoogleFonts.manrope(
                fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: body,
    );
  }

  Widget _content() {
    final d = _data!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            AvatarCircle(profile: d.profile, size: 72),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.profile.displayName,
                      style: GoogleFonts.unbounded(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(
                      d.role == 'campmaker'
                          ? 'Організовує походи'
                          : 'Ходить у походи',
                      style: GoogleFonts.manrope(
                          fontSize: 13, color: AppColors.textSecondary)),
                  if (_rating.count > 0) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      StarRating(value: _rating.average, size: 16),
                      const SizedBox(width: 6),
                      Text(
                          '${_rating.average.toStringAsFixed(1)} · ${_rating.count}',
                          style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (d.bio != null && d.bio!.trim().isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
                color: AppColors.cream, borderRadius: AppShapes.leaf),
            padding: const EdgeInsets.all(16),
            child: Text(d.bio!,
                style: GoogleFonts.manrope(
                    fontSize: 15, height: 1.5, color: AppColors.textPrimary)),
          ),
        ],
        const SizedBox(height: 24),
        Text('ВІДГУКИ',
            style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        if (_reviews.isEmpty)
          Text('Поки без відгуків.',
              style: GoogleFonts.manrope(color: AppColors.textSecondary))
        else
          for (final r in _reviews) _ReviewTile(review: r),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});
  final Review review;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(
          color: AppColors.cream, borderRadius: AppShapes.leaf),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (review.author != null) ...[
                AvatarCircle(profile: review.author!, size: 32),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(review.author!.displayName,
                      style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                ),
              ] else
                const Spacer(),
              StarRating(value: review.rating.toDouble(), size: 14),
            ],
          ),
          if (review.body != null && review.body!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.body!,
                style: GoogleFonts.manrope(
                    fontSize: 14, height: 1.5, color: AppColors.textPrimary)),
          ],
        ],
      ),
    );
  }
}
