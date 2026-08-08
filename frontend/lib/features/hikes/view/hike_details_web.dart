import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shapes.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/web/widgets/web_chrome.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../../core/widgets/hike_cover.dart';
import '../../favorites/cubit/favorites_cubit.dart';
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

  @override
  void initState() {
    super.initState();
    _repo.fetchItinerary(hike.id).then((d) {
      if (mounted) setState(() => _itinerary = d);
    });
  }

  Future<void> _join() async {
    setState(() => _joining = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.requestToJoin(hike.id);
      messenger.showSnackBar(const SnackBar(
          content: Text('Заявку надіслано! Організатор отримає сповіщення.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _joining = false);
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
                Row(children: [
                  AvatarCircle(profile: hike.organizer, size: 48),
                  const SizedBox(width: 14),
                  Text(hike.organizer.displayName,
                      style: GoogleFonts.manrope(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 40),
          SizedBox(width: 340, child: _BookingCard(
            hike: hike,
            joining: _joining,
            isFavorite: isFav,
            onJoin: _join,
            onFavorite: () => context.read<FavoritesCubit>().toggle(hike),
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
    required this.onJoin,
    required this.onFavorite,
  });
  final Hike hike;
  final bool joining;
  final bool isFavorite;
  final VoidCallback onJoin;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
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
          Text(hike.isFree ? 'без оплати організатору' : 'з особи',
              style: GoogleFonts.manrope(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: Material(
              color: AppColors.accent,
              borderRadius: AppShapes.leaf,
              child: InkWell(
                borderRadius: AppShapes.leaf,
                onTap: joining ? null : onJoin,
                child: Center(
                  child: joining
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.cream))
                      : Text('Хочу приєднатися',
                          style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.cream)),
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
