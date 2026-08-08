import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shapes.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../../core/widgets/hike_cover.dart';
import '../../hikes/data/hikes_repository.dart';
import '../../hikes/data/models/hike.dart';
import '../cubit/home_cubit.dart';

/// Home / browse tab. Node: terrain-home (94:38).
class HomePage extends StatelessWidget {
  const HomePage({super.key, this.onOpenSearch, this.onOpenHike});

  final VoidCallback? onOpenSearch;
  final void Function(Hike hike)? onOpenHike;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => HomeCubit(ctx.read<HikesRepository>()),
      child: _HomeView(onOpenSearch: onOpenSearch, onOpenHike: onOpenHike),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView({this.onOpenSearch, this.onOpenHike});

  final VoidCallback? onOpenSearch;
  final void Function(Hike hike)? onOpenHike;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: Builder(
        builder: (context) => FloatingActionButton.extended(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.cream,
          icon: const Icon(Icons.add),
          label: Text('Створити',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
          onPressed: () async {
            final created = await context.push<bool>('/create-hike');
            if (created == true && context.mounted) {
              context.read<HomeCubit>().load();
            }
          },
        ),
      ),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () => context.read<HomeCubit>().load(),
            color: AppColors.accent,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _HeroWithConsole(onOpenSearch: onOpenSearch),
                ),
                if (state.status == HomeStatus.loading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                    sliver: SliverList.list(
                      children: [
                        Text('Зараз збираються',
                            style: GoogleFonts.manrope(
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            )),
                        const SizedBox(height: 16),
                        for (final hike in state.gathering) ...[
                          _GatheringCard(
                            hike: hike,
                            onTap: () => onOpenHike?.call(hike),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (state.recommendation != null) ...[
                          const SizedBox(height: 16),
                          _RecommendationCard(
                            hike: state.recommendation!,
                            onTap: () => onOpenHike?.call(state.recommendation!),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeroWithConsole extends StatelessWidget {
  const _HeroWithConsole({this.onOpenSearch});
  final VoidCallback? onOpenSearch;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final heroHeight = 300.0 + topInset;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Sizing spacer: hero height + room for the console that overhangs it.
        SizedBox(width: double.infinity, height: heroHeight + 140),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: heroHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/images/home_hero.jpg', fit: BoxFit.cover),
              const ColoredBox(color: Color(0x73263237)),
              Padding(
                padding: EdgeInsets.fromLTRB(20, topInset + 12, 20, 44),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('BlaBlaCamp',
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.cream,
                            )),
                        Text('серпень 2026 · карпати',
                            style: GoogleFonts.ibmPlexMono(
                              fontSize: 11,
                              color: AppColors.mutedOnDark,
                            )),
                      ],
                    ),
                    const Spacer(),
                    Text('Куди поїдемо,\nколи місто відпустить?',
                        style: GoogleFonts.unbounded(
                          fontSize: 22,
                          height: 28 / 22,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cream,
                        )),
                    const SizedBox(height: 8),
                    Text('Обери дати. Подивись, хто вже збирається.',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: AppColors.mutedOnDark,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          top: heroHeight - 20,
          child: _SearchConsole(onTap: onOpenSearch),
        ),
      ],
    );
  }
}

class _SearchConsole extends StatefulWidget {
  const _SearchConsole({this.onTap});
  final VoidCallback? onTap;

  @override
  State<_SearchConsole> createState() => _SearchConsoleState();
}

class _SearchConsoleState extends State<_SearchConsole> {
  static const _cities = [
    'Львів', 'Київ', 'Івано-Франківськ', 'Ужгород', 'Чернівці'
  ];
  static const _regions = [
    'Карпати', 'Боржава', 'Свидовець', 'Чорногора', 'Мармароси'
  ];

  String _from = 'Львів';
  String _where = 'Карпати';
  DateTimeRange? _dates = DateTimeRange(
    start: DateTime(2026, 8, 14),
    end: DateTime(2026, 8, 18),
  );

  String get _datesLabel =>
      _dates == null ? 'Будь-коли' : formatDateRange(_dates!.start, _dates!.end);

  Future<void> _pickOption(
      String title, List<String> options, ValueChanged<String> onPick) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            for (final o in options)
              ListTile(
                title: Text(o,
                    style: GoogleFonts.manrope(
                        fontSize: 16, color: AppColors.textPrimary)),
                onTap: () => Navigator.of(ctx).pop(o),
              ),
          ],
        ),
      ),
    );
    if (picked != null) onPick(picked);
  }

  Future<void> _pickDates() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime(2027, 12, 31),
      initialDateRange: _dates,
    );
    if (range != null) setState(() => _dates = range);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: AppShapes.leaf,
        boxShadow: const [
          BoxShadow(
            color: Color(0x22121719),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ConsoleField(
                  label: 'Звідки?',
                  value: _from,
                  onTap: () => _pickOption('Звідки?', _cities,
                      (v) => setState(() => _from = v)),
                ),
              ),
              const _ConsoleDivider(),
              Expanded(
                child: _ConsoleField(
                  label: 'Коли?',
                  value: _datesLabel,
                  onTap: _pickDates,
                ),
              ),
              const _ConsoleDivider(),
              Expanded(
                child: _ConsoleField(
                  label: 'Куди?',
                  value: _where,
                  onTap: () => _pickOption('Куди?', _regions,
                      (v) => setState(() => _where = v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: Material(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: widget.onTap,
                child: Center(
                  child: Text('Знайти своїх',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.cream,
                      )),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsoleField extends StatelessWidget {
  const _ConsoleField(
      {required this.label, required this.value, this.onTap});
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(),
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF747A78),
                )),
            const SizedBox(height: 4),
            Row(
              children: [
                Flexible(
                  child: Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      )),
                ),
                const Icon(Icons.keyboard_arrow_down,
                    size: 16, color: Color(0xFF747A78)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsoleDivider extends StatelessWidget {
  const _ConsoleDivider();
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        color: AppColors.divider,
      );
}

class _GatheringCard extends StatelessWidget {
  const _GatheringCard({required this.hike, this.onTap});
  final Hike hike;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: AppShapes.leaf,
          border: Border.all(color: AppColors.divider),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0F121719), blurRadius: 10, offset: Offset(0, 3)),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HikeCover(
              hike: hike,
              width: 68,
              height: 68,
              borderRadius: AppShapes.leafOf(14, 4),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _TypeChip(hike: hike),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          formatDateRange(hike.startDate, hike.endDate),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 11,
                            color: const Color(0xFF52727D),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hike.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (hike.summary != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      hike.summary!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      AvatarCircle(profile: hike.organizer, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${hike.organizer.displayName} · ${hike.region ?? ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
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

/// Small colored pill for the hike type (shared / guided).
class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.hike});
  final Hike hike;

  @override
  Widget build(BuildContext context) {
    final isShared = hike.type == HikeType.shared;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isShared ? const Color(0xFF445447) : const Color(0xFF263237),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isShared ? 'Спільний' : 'З гідом',
        style: GoogleFonts.manrope(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.cream,
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.hike, this.onTap});
  final Hike hike;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFDDD9CF),
          borderRadius: AppShapes.leaf,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ПОХІД, ЯКИЙ ПІДІЙДЕ ДО ТВОГО НАПЛІЧНИКА',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                )),
            const SizedBox(height: 14),
            Row(
              children: [
                ClipRRect(
                  borderRadius: AppShapes.leafOf(12, 4),
                  child: Image.asset('assets/images/rec_photo.jpg',
                      width: 100, height: 80, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hike.summary ?? hike.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${hike.durationDays}-денний вихід · ${hike.difficulty.label} рівень',
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
