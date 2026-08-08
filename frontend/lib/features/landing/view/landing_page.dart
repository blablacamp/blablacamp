import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shapes.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/web/widgets/web_footer.dart';
import '../../../core/web/widgets/web_nav_bar.dart';
import '../../../core/widgets/hike_cover.dart';
import '../../hikes/data/hikes_repository.dart';
import '../../hikes/data/models/hike.dart';
import '../../home/cubit/home_cubit.dart';

/// Web marketing landing. Reuses [HomeCubit] for the live "gathering" feed.
/// Node: screen-landing (105:655).
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => HomeCubit(ctx.read<HikesRepository>()),
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: SingleChildScrollView(
          child: Column(
            children: [
              const _Hero(),
              const SizedBox(height: 64),
              const _HowItWorks(),
              const SizedBox(height: 64),
              const _Gathering(),
              const SizedBox(height: 64),
              const WebFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 560,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/home_hero.jpg', fit: BoxFit.cover),
          const ColoredBox(color: Color(0x99121719)),
          Column(
            children: [
              const WebNavBar(onDark: true),
              Expanded(
                child: MaxWidth(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 720,
                        child: Text(
                          'Незнайомі на вокзалі.\nСвої — на зворотній дорозі.',
                          style: GoogleFonts.unbounded(
                            fontSize: 46,
                            height: 1.15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.cream,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Знайди похід і людей, з якими захочеться піти ще раз.',
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            color: AppColors.mutedOnDark,
                          )),
                      const SizedBox(height: 32),
                      const _SearchBar(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 860),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: AppShapes.leaf,
        boxShadow: const [
          BoxShadow(color: Color(0x33121719), blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Expanded(child: _Field(label: 'Звідки?', value: 'Львів')),
          _divider(),
          const Expanded(child: _Field(label: 'Коли?', value: '14–18 серпня')),
          _divider(),
          const Expanded(child: _Field(label: 'Куди?', value: 'Карпати')),
          const SizedBox(width: 14),
          SizedBox(
            height: 52,
            child: Material(
              color: AppColors.accent,
              borderRadius: AppShapes.leafOf(14, 6),
              child: InkWell(
                borderRadius: AppShapes.leafOf(14, 6),
                onTap: () => context.push('/search'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Center(
                    child: Text('Знайти своїх',
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.cream,
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

  Widget _divider() => Container(
      width: 1, height: 36, margin: const EdgeInsets.symmetric(horizontal: 14), color: AppColors.divider);
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: GoogleFonts.manrope(
                fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF747A78))),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.manrope(
                fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('01', 'Обери похід', 'Фільтруй за напрямком, датами й рівнем. Дивись, хто вже збирається.'),
      ('02', 'Приєднайся чи створи', 'Подай заявку до групи або збери власну — ти вирішуєш.'),
      ('03', 'Рушай', 'Чеклист спорядження, чат групи й нагадування — усе під рукою.'),
    ];
    return MaxWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Як це працює',
              style: GoogleFonts.unbounded(
                  fontSize: 30, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (n, title, body) in steps) ...[
                Expanded(child: _StepCard(n: n, title: title, body: body)),
                if (n != '03') const SizedBox(width: 20),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.n, required this.title, required this.body});
  final String n;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppShapes.leaf,
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(n,
              style: GoogleFonts.unbounded(
                  fontSize: 34, fontWeight: FontWeight.w700, color: AppColors.accent)),
          const SizedBox(height: 16),
          Text(title,
              style: GoogleFonts.manrope(
                  fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(body,
              style: GoogleFonts.manrope(
                  fontSize: 15, height: 1.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _Gathering extends StatelessWidget {
  const _Gathering();

  @override
  Widget build(BuildContext context) {
    return MaxWidth(
      child: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          final hikes = state.gathering.take(3).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Зараз збираються',
                      style: GoogleFonts.unbounded(
                          fontSize: 30, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  TextButton(
                    onPressed: () => context.push('/search'),
                    child: Text('Всі походи →',
                        style: GoogleFonts.manrope(
                            fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.accent)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (state.status == HomeStatus.loading)
                const Center(child: CircularProgressIndicator(color: AppColors.accent))
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < hikes.length; i++) ...[
                      Expanded(
                        child: _LandingCard(
                          hike: hikes[i],
                          onTap: () => context.push('/hike', extra: hikes[i]),
                        ),
                      ),
                      if (i < hikes.length - 1) const SizedBox(width: 20),
                    ],
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LandingCard extends StatelessWidget {
  const _LandingCard({required this.hike, required this.onTap});
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
            HikeCover(hike: hike, height: 180),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hike.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                          fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  if (hike.summary != null) ...[
                    const SizedBox(height: 6),
                    Text(hike.summary!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                            fontSize: 14, height: 1.4, color: AppColors.textSecondary)),
                  ],
                  const SizedBox(height: 10),
                  Text(
                      '${formatDateRange(hike.startDate, hike.endDate)} · ${hike.region ?? ''} · ${hike.type.label}',
                      style: GoogleFonts.ibmPlexMono(
                          fontSize: 12, color: const Color(0xFF52727D))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
