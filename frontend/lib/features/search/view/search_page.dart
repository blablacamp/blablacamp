import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shapes.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/app_search_field.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../../core/widgets/hike_cover.dart';
import '../../hikes/data/hikes_repository.dart';
import '../../hikes/data/models/hike.dart';
import '../cubit/search_cubit.dart';

/// Search results. Node: terrain-search (94:128).
class SearchPage extends StatelessWidget {
  const SearchPage({super.key, this.onOpenHike, this.initialQuery});

  final void Function(Hike hike)? onOpenHike;
  final String? initialQuery;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) {
        final cubit = SearchCubit(ctx.read<HikesRepository>());
        if (initialQuery != null && initialQuery!.isNotEmpty) {
          cubit.setQuery(initialQuery!);
        }
        return cubit;
      },
      child: _SearchView(onOpenHike: onOpenHike),
    );
  }
}

class _SearchView extends StatelessWidget {
  const _SearchView({this.onOpenHike});
  final void Function(Hike hike)? onOpenHike;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: BlocBuilder<SearchCubit, SearchState>(
        builder: (context, state) {
          final cubit = context.read<SearchCubit>();
          final hikes = state.visible;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            children: [
              Text('ЛЬВІВ → КАРПАТИ · 14–18 СЕРП.',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 12,
                    color: const Color(0xFF747A78),
                  )),
              const SizedBox(height: 6),
              Text('Є ${hikes.length} варіантів на твоє вікно',
                  style: GoogleFonts.manrope(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  )),
              const SizedBox(height: 16),
              AppSearchField(
                hint: 'Куди хочеш? Напр. «Боржава»',
                onChanged: cubit.setQuery,
              ),
              const SizedBox(height: 20),
              _FilterRow(
                active: state.filter,
                onSelect: cubit.setFilter,
              ),
              const SizedBox(height: 20),
              if (state.status == SearchStatus.loading)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                )
              else
                for (var i = 0; i < hikes.length; i++) ...[
                  if (hikes[i].type == HikeType.shared)
                    _FeaturedCard(
                        hike: hikes[i], onTap: () => onOpenHike?.call(hikes[i]))
                  else
                    _GuidedCard(
                        hike: hikes[i], onTap: () => onOpenHike?.call(hikes[i])),
                  if (i < hikes.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(height: 1, color: AppColors.divider),
                    ),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.active, required this.onSelect});
  final HikeFilter active;
  final void Function(HikeFilter) onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterTab(
            label: 'Усі', selected: active == null, onTap: () => onSelect(null)),
        const SizedBox(width: 16),
        _FilterTab(
            label: 'Тур із гідом',
            selected: active == HikeType.guided,
            onTap: () => onSelect(HikeType.guided)),
        const SizedBox(width: 16),
        _FilterTab(
            label: 'Спільний похід',
            selected: active == HikeType.shared,
            onTap: () => onSelect(HikeType.shared)),
      ],
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color:
                      selected ? AppColors.textPrimary : const Color(0xFF747A78),
                )),
            const SizedBox(height: 4),
            Container(
              height: 2,
              color: selected ? AppColors.accent : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

String _techStrip(Hike h) {
  final parts = <String>[formatDateRange(h.startDate, h.endDate).toUpperCase()];
  if (h.durationDays > 1) parts.add('${h.durationDays} ДНІ');
  if (h.distanceKm != null) parts.add('${h.distanceKm!.toStringAsFixed(0)} КМ');
  return parts.join(' · ');
}

class _TypeTag extends StatelessWidget {
  const _TypeTag({required this.hike});
  final Hike hike;
  @override
  Widget build(BuildContext context) {
    final isShared = hike.type == HikeType.shared;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isShared ? const Color(0xFF445447) : const Color(0xFF263237),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(isShared ? 'Спільний похід' : 'Тур із гідом',
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.cream,
          )),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.hike, this.onTap});
  final Hike hike;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HikeCover(
            hike: hike,
            height: 190,
            borderRadius: AppShapes.leaf,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hike.title,
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    )),
                if (hike.summary != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    color: AppColors.cream,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text('«${hike.summary}»',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        )),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    AvatarCircle(profile: hike.organizer, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Організовує ${hike.organizer.displayName}',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              )),
                          Text(
                              '${hike.location ?? hike.region ?? ''} · Спільний похід без оплати організатору',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF747A78),
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(_techStrip(hike),
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          )),
                    ),
                    _TypeTag(hike: hike),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidedCard extends StatelessWidget {
  const _GuidedCard({required this.hike, this.onTap});
  final Hike hike;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        )),
                    if (hike.summary != null) ...[
                      const SizedBox(height: 4),
                      Text(hike.summary!,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          )),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              AvatarCircle(profile: hike.organizer, size: 24),
              const SizedBox(width: 8),
              Text(hike.organizer.displayName,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  )),
            ],
          ),
          const SizedBox(height: 12),
          Text(_techStrip(hike),
              style: GoogleFonts.ibmPlexMono(
                fontSize: 12,
                color: const Color(0xFF747A78),
              )),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(hike.priceLabel,
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        )),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text('Трансфер · ночівля · супровід',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: const Color(0xFF747A78),
                          )),
                    ),
                  ],
                ),
              ),
              _TypeTag(hike: hike),
            ],
          ),
        ],
      ),
    );
  }
}
