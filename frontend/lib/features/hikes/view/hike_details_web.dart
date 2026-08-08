import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/moderation/report_sheet.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shapes.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/web/widgets/web_chrome.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../../core/widgets/hike_cover.dart';
import '../../../core/widgets/hike_participants.dart';
import '../../../core/widgets/hike_route_map.dart';
import '../../../core/widgets/star_rating.dart';
import '../data/models/profile_ref.dart';
import '../data/models/waypoint.dart';
import '../../favorites/cubit/favorites_cubit.dart';
import '../../messages/view/chat_page.dart';
import '../data/hikes_repository.dart';
import '../data/models/hike.dart';
import '../data/models/hike_day.dart';

/// Web hike detail: two columns — content + sticky booking card.
class HikeDetailsWebPage extends StatefulWidget {
  const HikeDetailsWebPage({super.key, required this.hike});
  final Hike hike;

  @override
  State<HikeDetailsWebPage> createState() => _HikeDetailsWebPageState();
}

class _HikeDetailsWebPageState extends State<HikeDetailsWebPage> {
  Hike get hike => widget.hike;
  HikesRepository get _repo => context.read<HikesRepository>();
  List<HikeDay> _itinerary = const [];
  bool _joining = false;
  String? _participation;
  bool _canReview = false;
  ({double average, int count}) _orgRating = (average: 0, count: 0);
  List<ProfileRef> _members = const [];
  List<Waypoint> _waypoints = const [];

  @override
  void initState() {
    super.initState();
    _loadExtras();
  }

  Future<void> _loadExtras() async {
    final days = await _repo.fetchItinerary(hike.id);
    final participation = await _repo.fetchMyParticipation(hike.id);
    final rating = await _repo.fetchUserRating(hike.organizer.id);
    final canReview =
        await _repo.canReview(subjectId: hike.organizer.id, hikeId: hike.id);
    final members = await _repo.fetchApprovedParticipants(hike.id);
    final waypoints = await _repo.fetchWaypoints(hike.id);
    if (!mounted) return;
    setState(() {
      _itinerary = days;
      _participation = participation;
      _orgRating = rating;
      _canReview = canReview;
      _members = members;
      _waypoints = waypoints;
    });
  }

  Future<void> _join() async {
    setState(() => _joining = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.requestToJoin(hike.id);
      if (mounted) setState(() => _participation = 'pending');
      messenger.showSnackBar(const SnackBar(
          content: Text('Заявку надіслано! Організатор отримає сповіщення.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  void _openChat() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChatPage(
        hikeId: hike.id,
        title: hike.title,
        repository: _repo,
      ),
    ));
  }

  void _report() {
    showReportSheet(
      context,
      repository: _repo,
      targetType: 'hike',
      targetId: hike.id,
      hikeId: hike.id,
      title: hike.title,
    );
  }

  Future<void> _leaveReview() async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<({int rating, String body})>(
      context: context,
      builder: (_) => _WebReviewDialog(subjectName: hike.organizer.displayName),
    );
    if (result == null) return;
    try {
      await _repo.addReview(
        subjectId: hike.organizer.id,
        hikeId: hike.id,
        rating: result.rating,
        body: result.body.isEmpty ? null : result.body,
      );
      messenger.showSnackBar(
          const SnackBar(content: Text('Дякуємо за відгук!')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isShared = hike.type == HikeType.shared;
    final isFav = context.watch<FavoritesCubit>().state.isFavorite(hike.id);
    return WebChrome(
      footer: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: AppShapes.leaf,
                  child: HikeCover(hike: hike, height: 380),
                ),
                const SizedBox(height: 20),
                Text(hike.title,
                    style: GoogleFonts.unbounded(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text(
                    '${formatDateRange(hike.startDate, hike.endDate)} · ${hike.region ?? ''} · ${hike.difficulty.label}',
                    style: GoogleFonts.ibmPlexMono(
                        fontSize: 13, color: const Color(0xFF52727D))),
                if (hike.summary != null) ...[
                  const SizedBox(height: 24),
                  _title('Чому саме цей похід'),
                  const SizedBox(height: 10),
                  Text(hike.summary!,
                      style: GoogleFonts.manrope(
                          fontSize: 16, height: 1.6, color: AppColors.textPrimary)),
                ],
                if (hike.highlights.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _title('Що на маршруті'),
                  const SizedBox(height: 12),
                  for (final h in hike.highlights) _check(h),
                ],
                if (_itinerary.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _title('Маршрут по днях'),
                  const SizedBox(height: 12),
                  for (final d in _itinerary) _day(d),
                ],
                if (hike.includes.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _title(isShared ? 'Що ділимо' : 'Що входить'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [for (final i in hike.includes) _chip(i)],
                  ),
                ],
                const SizedBox(height: 24),
                _title(isShared ? 'Хто організовує' : 'Ваш гід'),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => context.push('/user/${hike.organizer.id}'),
                  borderRadius: AppShapes.leaf,
                  child: Row(children: [
                  AvatarCircle(profile: hike.organizer, size: 48),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(hike.organizer.displayName,
                          style: GoogleFonts.manrope(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      if (_orgRating.count > 0)
                        Row(children: [
                          StarRating(value: _orgRating.average, size: 15),
                          const SizedBox(width: 6),
                          Text(
                              '${_orgRating.average.toStringAsFixed(1)} · ${_orgRating.count} відгуків',
                              style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary)),
                        ])
                      else
                        Text('Ще без відгуків',
                            style: GoogleFonts.manrope(
                                fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ]),
                ),
                if (_canReview) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _leaveReview,
                    icon: const Icon(Icons.rate_review_outlined, size: 18),
                    label: const Text('Залишити відгук'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.accent),
                  ),
                ],
                if (_waypoints.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _title('Маршрут на карті'),
                  const SizedBox(height: 12),
                  HikeRouteMap(waypoints: _waypoints, height: 320),
                ],
                const SizedBox(height: 24),
                _title('Хто вже йде'),
                const SizedBox(height: 12),
                HikeParticipants(
                  members: _members,
                  max: hike.maxParticipants,
                  organizer: hike.organizer,
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
          SizedBox(width: 340, child: _BookingCard(
            hike: hike,
            joining: _joining,
            isFavorite: isFav,
            participation: _participation,
            onJoin: _join,
            onOpenChat: _openChat,
            onFavorite: () => context.read<FavoritesCubit>().toggle(hike),
            onReport: _report,
          )),
        ],
      ),
    );
  }

  Widget _title(String t) => Text(t.toUpperCase(),
      style: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: AppColors.textSecondary));

  Widget _check(String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.check_circle, size: 18, color: Color(0xFF47725B)),
          const SizedBox(width: 10),
          Expanded(
              child: Text(t,
                  style: GoogleFonts.manrope(
                      fontSize: 15, color: AppColors.textPrimary))),
        ]),
      );

  Widget _day(HikeDay d) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ДЕНЬ ${d.dayNum}',
              style: GoogleFonts.ibmPlexMono(fontSize: 11, color: AppColors.accent)),
          Text(d.title,
              style: GoogleFonts.manrope(
                  fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          if (d.description != null)
            Text(d.description!,
                style: GoogleFonts.manrope(
                    fontSize: 14, height: 1.4, color: AppColors.textSecondary)),
        ]),
      );

  Widget _chip(String l) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider)),
        child: Text(l,
            style: GoogleFonts.manrope(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      );
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.hike,
    required this.joining,
    required this.isFavorite,
    required this.participation,
    required this.onJoin,
    required this.onOpenChat,
    required this.onFavorite,
    required this.onReport,
  });
  final Hike hike;
  final bool joining;
  final bool isFavorite;
  final String? participation;
  final VoidCallback onJoin;
  final VoidCallback onOpenChat;
  final VoidCallback onFavorite;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final approved = participation == 'approved';
    final pending = participation == 'pending';
    final rejected = participation == 'rejected';
    final blocked = pending || rejected;
    final (label, onTap) = switch (participation) {
      'approved' => ('Відкрити чат групи', onOpenChat),
      'pending' => ('Заявку надіслано', null),
      'rejected' => ('Заявку відхилено', null),
      _ => ('Хочу приєднатися', onJoin),
    };
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: AppShapes.leaf,
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(color: Color(0x14121719), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(hike.isFree ? 'Безкоштовно' : hike.priceLabel,
              style: GoogleFonts.unbounded(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: hike.isFree ? AppColors.success : AppColors.textPrimary)),
          Text(
              pending
                  ? 'очікує підтвердження'
                  : rejected
                      ? 'на жаль, не цього разу'
                      : approved
                          ? 'ти в команді 🎒'
                          : hike.isFree
                              ? 'без оплати організатору'
                              : 'з особи',
              style: GoogleFonts.manrope(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: Material(
              color: blocked ? AppColors.divider : AppColors.accent,
              borderRadius: AppShapes.leaf,
              child: InkWell(
                borderRadius: AppShapes.leaf,
                onTap: (joining || blocked) ? null : onTap,
                child: Center(
                  child: joining
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.cream))
                      : Text(label,
                          style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: blocked
                                  ? AppColors.textSecondary
                                  : AppColors.cream)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onFavorite,
              icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: AppColors.accent, size: 20),
              label: Text(isFavorite ? 'В обраному' : 'Зберегти',
                  style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.divider),
                shape: RoundedRectangleBorder(borderRadius: AppShapes.leaf),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _row('Група', 'до ${hike.maxParticipants} осіб'),
          _row('Тривалість', '${hike.durationDays} дн.'),
          if (hike.distanceKm != null)
            _row('Відстань', '${hike.distanceKm!.toStringAsFixed(0)} км'),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onReport,
              icon: const Icon(Icons.flag_outlined, size: 16),
              label: const Text('Поскаржитися'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(k,
              style: GoogleFonts.manrope(fontSize: 14, color: AppColors.textSecondary)),
          Text(v,
              style: GoogleFonts.manrope(
                  fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ]),
      );
}

class _WebReviewDialog extends StatefulWidget {
  const _WebReviewDialog({required this.subjectName});
  final String subjectName;

  @override
  State<_WebReviewDialog> createState() => _WebReviewDialogState();
}

class _WebReviewDialogState extends State<_WebReviewDialog> {
  int _rating = 5;
  final _body = TextEditingController();

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cream,
      title: Text('Відгук про ${widget.subjectName}',
          style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StarRatingInput(
              value: _rating,
              onChanged: (v) => setState(() => _rating = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _body,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Як пройшов похід?'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Скасувати'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
          onPressed: () => Navigator.pop(
              context, (rating: _rating, body: _body.text.trim())),
          child: const Text('Надіслати'),
        ),
      ],
    );
  }
}
