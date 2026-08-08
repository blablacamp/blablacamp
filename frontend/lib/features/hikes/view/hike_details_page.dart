import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/moderation/report_sheet.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shapes.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../../core/widgets/hike_cover.dart';
import '../../../core/widgets/hike_participants.dart';
import '../../../core/widgets/star_rating.dart';
import '../data/models/profile_ref.dart';
import '../../favorites/cubit/favorites_cubit.dart';
import '../../messages/view/chat_page.dart';
import '../data/hikes_repository.dart';
import '../data/models/hike.dart';
import '../data/models/hike_day.dart';
import 'hike_details_web.dart';

/// Loads a hike by id (used for push deep-links) then shows [HikeDetailsPage].
class HikeDetailsLoader extends StatelessWidget {
  const HikeDetailsLoader({super.key, required this.hikeId});

  final String hikeId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Hike>(
      future: context.read<HikesRepository>().fetchById(hikeId),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: AppColors.surface,
            body: Center(
                child: CircularProgressIndicator(color: AppColors.accent)),
          );
        }
        if (!snap.hasData) {
          return Scaffold(
            backgroundColor: AppColors.surface,
            appBar: AppBar(backgroundColor: AppColors.surface),
            body: const Center(child: Text('Похід не знайдено')),
          );
        }
        final hike = snap.data!;
        return ResponsiveLayout(
          mobile: (c) => HikeDetailsPage(hike: hike),
          desktop: (c) => HikeDetailsWebPage(hike: hike),
        );
      },
    );
  }
}

/// Hike detail. One adaptive layout covering both the guided (94:213) and
/// shared (94:336) designs — sections switch on [Hike.type].
class HikeDetailsPage extends StatefulWidget {
  const HikeDetailsPage({super.key, required this.hike});

  final Hike hike;

  @override
  State<HikeDetailsPage> createState() => _HikeDetailsPageState();
}

class _HikeDetailsPageState extends State<HikeDetailsPage> {
  bool _joining = false;
  List<HikeDay> _itinerary = const [];
  String? _participation; // approved | pending | rejected | null
  bool _canReview = false;
  ({double average, int count}) _orgRating = (average: 0, count: 0);
  List<ProfileRef> _members = const [];

  Hike get hike => widget.hike;
  HikesRepository get _repo => context.read<HikesRepository>();

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
    if (!mounted) return;
    setState(() {
      _itinerary = days;
      _participation = participation;
      _orgRating = rating;
      _canReview = canReview;
      _members = members;
    });
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

  Future<void> _join() async {
    setState(() => _joining = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.requestToJoin(hike.id);
      if (mounted) setState(() => _participation = 'pending');
      messenger.showSnackBar(const SnackBar(
        content: Text('Заявку надіслано! Організатор отримає сповіщення.'),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _leaveReview() async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<({int rating, String body})>(
      context: context,
      builder: (_) => _ReviewDialog(subjectName: hike.organizer.displayName),
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
    final isFavorite =
        context.watch<FavoritesCubit>().state.isFavorite(hike.id);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _Hero(
              hike: hike,
              isFavorite: isFavorite,
              onFavorite: () => context.read<FavoritesCubit>().toggle(hike),
              onReport: _report,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            sliver: SliverList.list(
              children: [
                if (hike.summary != null) ...[
                  const _SectionTitle('Чому саме цей похід'),
                  const SizedBox(height: 10),
                  Text(hike.summary!,
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        height: 1.5,
                        color: AppColors.textPrimary,
                      )),
                  const SizedBox(height: 24),
                ],
                if (hike.highlights.isNotEmpty) ...[
                  const _SectionTitle('Що на маршруті'),
                  const SizedBox(height: 12),
                  _Panel(
                    child: Column(
                      children: [
                        for (final h in hike.highlights) _CheckRow(text: h),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                _SectionTitle(isShared ? 'Хто організовує' : 'Ваш гід'),
                const SizedBox(height: 12),
                _OrganizerCard(hike: hike, rating: _orgRating),
                if (_canReview) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _leaveReview,
                      icon: const Icon(Icons.rate_review_outlined, size: 18),
                      label: const Text('Залишити відгук'),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.accent),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                const _SectionTitle('Хто вже йде'),
                const SizedBox(height: 12),
                _Panel(
                  child: HikeParticipants(
                    members: _members,
                    max: hike.maxParticipants,
                    organizer: hike.organizer,
                  ),
                ),
                if (hike.description != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    color: AppColors.cream,
                    padding: const EdgeInsets.all(16),
                    child: Text(hike.description!,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          height: 1.5,
                          color: AppColors.textPrimary,
                        )),
                  ),
                ],
                if (_itinerary.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const _SectionTitle('Маршрут по днях'),
                  const SizedBox(height: 12),
                  _Panel(
                    child: Column(
                      children: [
                        for (var i = 0; i < _itinerary.length; i++) ...[
                          _DayRow(day: _itinerary[i]),
                          if (i < _itinerary.length - 1)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child:
                                  Divider(height: 1, color: AppColors.divider),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
                if (hike.includes.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _SectionTitle(isShared ? 'Що ділимо' : 'Що входить'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final item in hike.includes) _Perk(label: item),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                const _SectionTitle('Деталі'),
                const SizedBox(height: 12),
                _RoutePanel(hike: hike),
                if (isShared) ...[
                  const SizedBox(height: 16),
                  const _NoFeeBox(),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _StickyBar(
        hike: hike,
        joining: _joining,
        participation: _participation,
        onJoin: _join,
        onOpenChat: _openChat,
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.hike,
    required this.isFavorite,
    required this.onFavorite,
    required this.onReport,
  });
  final Hike hike;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: 320 + topInset,
      child: Stack(
        fit: StackFit.expand,
        children: [
          HikeCover(hike: hike),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x33121719), Color(0xE6121719)],
                stops: [0.35, 1],
              ),
            ),
          ),
          Positioned(
            top: topInset + 8,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CircleButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                Row(
                  children: [
                    _CircleButton(
                      icon: Icons.flag_outlined,
                      onTap: onReport,
                    ),
                    const SizedBox(width: 8),
                    _CircleButton(
                      icon:
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? AppColors.accent : AppColors.cream,
                      onTap: onFavorite,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hike.type == HikeType.shared
                        ? const Color(0xFF445447)
                        : const Color(0xFF263237),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(hike.type.label,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cream,
                      )),
                ),
                const SizedBox(height: 10),
                Text(hike.title,
                    style: GoogleFonts.unbounded(
                      fontSize: 24,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cream,
                    )),
                const SizedBox(height: 6),
                Text(
                    '${formatDateRange(hike.startDate, hike.endDate)} · ${hike.region ?? ''}',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 12,
                      color: AppColors.mutedOnDark,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.color = AppColors.cream,
  });
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x66121719),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      style: GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: AppColors.textSecondary,
      ));
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: AppShapes.leaf,
        ),
        padding: const EdgeInsets.all(18),
        child: child,
      );
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 18, color: Color(0xFF47725B)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                )),
          ),
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.day});
  final HikeDay day;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ДЕНЬ ${day.dayNum}',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              color: AppColors.accent,
            )),
        const SizedBox(height: 2),
        Text(day.title,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            )),
        if (day.description != null) ...[
          const SizedBox(height: 2),
          Text(day.description!,
              style: GoogleFonts.manrope(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textSecondary,
              )),
        ],
      ],
    );
  }
}

class _Perk extends StatelessWidget {
  const _Perk({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(label,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          )),
    );
  }
}

class _OrganizerCard extends StatelessWidget {
  const _OrganizerCard({required this.hike, required this.rating});
  final Hike hike;
  final ({double average, int count}) rating;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Row(
        children: [
          AvatarCircle(profile: hike.organizer, size: 56),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hike.organizer.displayName,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    )),
                const SizedBox(height: 4),
                Text(
                    hike.type == HikeType.guided
                        ? 'Сертифікований гід'
                        : 'Організатор спільного походу',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    )),
                if (rating.count > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      StarRating(value: rating.average, size: 16),
                      const SizedBox(width: 6),
                      Text(
                          '${rating.average.toStringAsFixed(1)} · ${rating.count} ${_reviewWord(rating.count)}',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          )),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  Text('Ще без відгуків',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _reviewWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'відгук';
    if ([2, 3, 4].contains(n % 10) && !(n % 100 >= 12 && n % 100 <= 14)) {
      return 'відгуки';
    }
    return 'відгуків';
  }
}

class _RoutePanel extends StatelessWidget {
  const _RoutePanel({required this.hike});
  final Hike hike;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      if (hike.distanceKm != null)
        ('Відстань', '${hike.distanceKm!.toStringAsFixed(0)} км'),
      ('Тривалість', '${hike.durationDays} дн.'),
      ('Складність', hike.difficulty.label),
      if (hike.location != null) ('Старт', hike.location!),
      ('Група', 'до ${hike.maxParticipants} осіб'),
    ];
    return _Panel(
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(rows[i].$1,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    )),
                Text(rows[i].$2,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    )),
              ],
            ),
            if (i < rows.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: AppColors.divider),
              ),
          ],
        ],
      ),
    );
  }
}

class _NoFeeBox extends StatelessWidget {
  const _NoFeeBox();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFDDD9CF),
        borderRadius: AppShapes.leaf,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Спільний похід без комісії',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 6),
          Text(
              'Ви не платите організатору. Спільні витрати — трансфер, газ і продукти — ділите між учасниками.',
              style: GoogleFonts.manrope(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textSecondary,
              )),
        ],
      ),
    );
  }
}

class _StickyBar extends StatelessWidget {
  const _StickyBar({
    required this.hike,
    required this.joining,
    required this.participation,
    required this.onJoin,
    required this.onOpenChat,
  });
  final Hike hike;
  final bool joining;
  final String? participation;
  final VoidCallback onJoin;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    // CTA depends on the current user's membership status.
    final approved = participation == 'approved';
    final pending = participation == 'pending';
    final rejected = participation == 'rejected';
    final enabled = !joining && (approved || participation == null);

    final (label, onTap, color) = switch (participation) {
      'approved' => ('Відкрити чат групи', onOpenChat, AppColors.accent),
      'pending' => ('Заявку надіслано', null, AppColors.divider),
      'rejected' => ('Заявку відхилено', null, AppColors.divider),
      _ => ('Хочу приєднатися', onJoin, AppColors.accent),
    };

    return Container(
      color: AppColors.cream,
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.paddingOf(context).bottom),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(hike.isFree ? 'Безкоштовно' : hike.priceLabel,
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color:
                        hike.isFree ? AppColors.success : AppColors.textPrimary,
                  )),
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
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  )),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 48,
              child: Material(
                color: color,
                borderRadius: AppShapes.leaf,
                child: InkWell(
                  borderRadius: AppShapes.leaf,
                  onTap: enabled ? onTap : null,
                  child: Center(
                    child: joining
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.cream),
                          )
                        : Text(label,
                            style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: (pending || rejected)
                                  ? AppColors.textSecondary
                                  : AppColors.cream,
                            )),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog({required this.subjectName});
  final String subjectName;

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
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
      content: Column(
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
            decoration: const InputDecoration(
              hintText: 'Як пройшов похід?',
            ),
          ),
        ],
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
