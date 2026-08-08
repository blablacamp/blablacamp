import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shapes.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/web/widgets/web_chrome.dart';
import '../../../core/widgets/app_search_field.dart';
import '../../../core/widgets/hike_cover.dart';
import '../../hikes/data/hikes_repository.dart';
import '../../hikes/data/models/hike.dart';
import '../cubit/search_cubit.dart';

/// Web browse/search: filters + responsive card grid. Reuses [SearchCubit].
class SearchWebPage extends StatelessWidget {
  const SearchWebPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => SearchCubit(ctx.read<HikesRepository>()),
      child: WebChrome(
        footer: true,
        child: BlocBuilder<SearchCubit, SearchState>(
          builder: (context, state) {
            final cubit = context.read<SearchCubit>();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Знайди свій похід',
                    style: GoogleFonts.unbounded(
                        fontSize: 34,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: AppSearchField(
                        hint: 'Куди хочеш? Напр. «Боржава»',
                        onChanged: cubit.setQuery,
                      ),
                    ),
                    const SizedBox(width: 16),
                    _Filters(active: state.filter, onSelect: cubit.setFilter),
                  ],
                ),
                const SizedBox(height: 28),
                if (state.status == SearchStatus.loading)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(
                        child: CircularProgressIndicator(color: AppColors.accent)),
                  )
                else if (state.hikes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Center(
                      child: Text('Нічого не знайдено',
                          style: GoogleFonts.manrope(
                              fontSize: 16, color: AppColors.textSecondary)),
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, c) {
                      const gap = 20.0;
                      final cols = c.maxWidth >= 1000 ? 3 : (c.maxWidth >= 660 ? 2 : 1);
                      final cardW = (c.maxWidth - gap * (cols - 1)) / cols;
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (final h in state.hikes)
                            SizedBox(
                              width: cardW,
                              child: _WebHikeCard(
                                hike: h,
                                onTap: () => context.go('/hike/${h.id}'),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                if (state.hasMore) ...[
                  const SizedBox(height: 24),
                  Center(
                    child: OutlinedButton(
                      onPressed: cubit.loadMore,
                      child: const Text('Показати ще'),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.active, required this.onSelect});
  final HikeType? active;
  final void Function(HikeType?) onSelect;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, HikeType? t) {
      final sel = active == t;
      return Padding(
        padding: const EdgeInsets.only(left: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: sel,
          onSelected: (_) => onSelect(t),
          selectedColor: AppColors.accent,
          backgroundColor: AppColors.cream,
          labelStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w600,
            color: sel ? AppColors.cream : AppColors.textPrimary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.divider),
          ),
          showCheckmark: false,
        ),
      );
    }

    return Row(children: [
      chip('Усі', null),
      chip('Гід', HikeType.guided),
      chip('Спільний', HikeType.shared),
    ]);
  }
}

class _WebHikeCard extends StatelessWidget {
  const _WebHikeCard({required this.hike, required this.onTap});
  final Hike hike;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: AppShapes.leaf,
          border: Border.all(color: AppColors.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HikeCover(hike: hike, height: 170),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hike.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  if (hike.summary != null) ...[
                    const SizedBox(height: 6),
                    Text(hike.summary!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                            fontSize: 14, height: 1.4, color: AppColors.textSecondary)),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                            '${formatDateRange(hike.startDate, hike.endDate)} · ${hike.region ?? ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.ibmPlexMono(
                                fontSize: 12, color: const Color(0xFF52727D))),
                      ),
                      Text(hike.isFree ? 'Безкоштовно' : hike.priceLabel,
                          style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
