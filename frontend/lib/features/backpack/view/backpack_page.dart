import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shapes.dart';
import '../../hikes/data/hikes_repository.dart';
import '../../hikes/data/models/checklist_item.dart';
import '../cubit/backpack_cubit.dart';

const _green = Color(0xFF47725B);
const _amber = Color(0xFFB78232);
const _blue = Color(0xFF52727D);
const _panelBorder = Color(0xFFD2D0C8);

/// "Мої походи" — the gear backpack checklist. Node: terrain-backpack (94:426).
class BackpackPage extends StatelessWidget {
  const BackpackPage({super.key, this.hikeId = 'sample-borzhava'});

  final String hikeId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) =>
          BackpackCubit(ctx.read<HikesRepository>(), hikeId: hikeId),
      child: const _BackpackView(),
    );
  }
}

class _BackpackView extends StatelessWidget {
  const _BackpackView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocBuilder<BackpackCubit, BackpackState>(
        builder: (context, state) {
          final missing = state.missing.length;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _Hero(missingCount: missing),
                    _ProgressStrip(missingGear: missing),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (state.missing.isNotEmpty) ...[
                            _NextActions(items: state.missing),
                            const SizedBox(height: 24),
                          ],
                          for (final entry in state.byCategory.entries) ...[
                            _Category(
                              title: entry.key,
                              items: entry.value,
                              onToggle: (i) =>
                                  context.read<BackpackCubit>().toggle(i),
                            ),
                            const SizedBox(height: 20),
                          ],
                          const _FriendlyMessage(
                            text:
                                '«Марта каже, що палиці можна забрати на вокзалі перед потягом.»',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _StickyBar(
                onCollect: state.missing.isEmpty
                    ? null
                    : () => _showMissingSheet(context, state),
                onRentKit: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Оренда комплекту в партнера — скоро. Ми повідомимо.'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showMissingSheet(BuildContext context, BackpackState state) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ще зібрати: ${state.missing.length}',
                  style: GoogleFonts.unbounded(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  )),
              const SizedBox(height: 16),
              for (final item in state.missing)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.radio_button_unchecked,
                          size: 18, color: AppColors.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                            '${item.name}${item.spec != null ? ' · ${item.spec}' : ''}',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            )),
                      ),
                      TextButton(
                        onPressed: () {
                          context.read<BackpackCubit>().toggle(item);
                          Navigator.of(sheetContext).pop();
                        },
                        child: Text('Позначив',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            )),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.missingCount});
  final int missingCount;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/backpack_hero.png',
                fit: BoxFit.cover),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xB0121719), Color(0xFF263237)],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, topInset + 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('БОРЖАВА · 15–16 СЕРПНЯ',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 11,
                      color: AppColors.mutedOnDark,
                    )),
                const SizedBox(height: 6),
                Text(
                    missingCount > 0
                        ? 'До старту бракує ${_plural(missingCount)}'
                        : 'Наплічник зібрано',
                    style: GoogleFonts.manrope(
                      fontSize: 29,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      color: AppColors.cream,
                    )),
                const SizedBox(height: 6),
                Text(
                    'Намет можна орендувати. Палиці може позичити Марта. Залізничний квиток ще не придбано.',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      height: 20 / 14,
                      color: AppColors.mutedOnDark,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _plural(int n) {
    final word = switch (n % 10) {
      1 when n % 100 != 11 => 'речі',
      _ => 'речей',
    };
    return '$n $word';
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({required this.missingGear});
  final int missingGear;

  @override
  Widget build(BuildContext context) {
    final steps = <(_Marker, String)>[
      (_Marker.done, 'Маршрут підходить'),
      (_Marker.done, 'Група підтвердила участь'),
      (
        missingGear > 0 ? _Marker.active : _Marker.done,
        missingGear > 0 ? 'Спорядження майже готове' : 'Спорядження зібране',
      ),
      (_Marker.todo, 'Квиток ще не придбано'),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(bottom: BorderSide(color: _panelBorder)),
      ),
      child: Column(
        children: [
          for (final (marker, label) in steps)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    child: Text(marker.glyph,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: marker.color,
                        )),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(label,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        )),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

enum _Marker {
  done('✓', _green),
  active('●', _amber),
  todo('○', Color(0xFF747A78));

  const _Marker(this.glyph, this.color);
  final String glyph;
  final Color color;
}

class _NextActions extends StatelessWidget {
  const _NextActions({required this.items});
  final List<ChecklistItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Найближчі дії',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            )),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cream,
            border: Border.all(color: _panelBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ПРІОРИТЕТНІ ЗАВДАННЯ',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF747A78),
                  )),
              const SizedBox(height: 12),
              for (var i = 0; i < items.length; i++) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                          '${items[i].name}${items[i].spec != null ? ' · ${items[i].spec}' : ''}',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          )),
                    ),
                    const SizedBox(width: 12),
                    Text(items[i].actionLabel ?? 'Зробити',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          color: items[i].status == ChecklistStatus.shared
                              ? _blue
                              : AppColors.accent,
                        )),
                  ],
                ),
                if (i < items.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: _panelBorder),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Category extends StatelessWidget {
  const _Category(
      {required this.title, required this.items, required this.onToggle});
  final String title;
  final List<ChecklistItem> items;
  final void Function(ChecklistItem) onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            )),
        const SizedBox(height: 10),
        for (final item in items)
          _ItemRow(item: item, onToggle: () => onToggle(item)),
        const SizedBox(height: 10),
        const Divider(height: 1, color: _panelBorder),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.onToggle});
  final ChecklistItem item;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    )),
                if (item.spec != null)
                  Text(item.spec!,
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 12,
                        color: const Color(0xFF747A78),
                      )),
              ],
            ),
          ),
          if (item.actionNote != null) ...[
            Text(item.actionNote!,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                )),
            const SizedBox(width: 6),
          ],
          _StatusChip(item: item, onTap: onToggle),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.item, required this.onTap});
  final ChecklistItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (item.status) {
      ChecklistStatus.packed => (_green, 'Є'),
      ChecklistStatus.shared => (_blue, item.actionLabel ?? 'Позичити'),
      ChecklistStatus.todo => (AppColors.accent, item.actionLabel ?? 'Додати'),
    };
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.cream,
            )),
      ),
    );
  }
}

class _FriendlyMessage extends StatelessWidget {
  const _FriendlyMessage({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFDDD9CF),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.divider,
            child: Icon(Icons.person, size: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                )),
          ),
        ],
      ),
    );
  }
}

class _StickyBar extends StatelessWidget {
  const _StickyBar({this.onCollect, this.onRentKit});

  final VoidCallback? onCollect;
  final VoidCallback? onRentKit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: _panelBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: Material(
              color: onCollect == null
                  ? AppColors.accent.withValues(alpha: 0.5)
                  : AppColors.accent,
              borderRadius: AppShapes.leafOf(18, 6),
              child: InkWell(
                borderRadius: AppShapes.leafOf(18, 6),
                onTap: onCollect,
                child: Center(
                  child: Text(
                      onCollect == null ? 'Усе зібрано ✓' : 'Зібрати відсутнє',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.cream,
                      )),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton(
              onPressed: onRentKit,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.textSecondary, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Орендувати комплект у партнера',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  )),
            ),
          ),
        ],
      ),
    );
  }
}
