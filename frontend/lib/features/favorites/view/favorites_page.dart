import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_search_field.dart';
import '../../../core/widgets/hike_list_tile.dart';
import '../../hikes/data/models/hike.dart';
import '../cubit/favorites_cubit.dart';

/// "Обране" tab — saved hikes with a local search filter. Reads the app-level
/// [FavoritesCubit] so likes made on the details screen show up immediately.
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  String _query = '';

  List<Hike> _filter(List<Hike> hikes) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return hikes;
    return hikes
        .where((h) =>
            h.title.toLowerCase().contains(q) ||
            (h.region ?? '').toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: BlocBuilder<FavoritesCubit, FavoritesState>(
          builder: (context, state) {
            final hikes = _filter(state.hikes);
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Обране',
                      style: GoogleFonts.unbounded(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      )),
                  const SizedBox(height: 12),
                  if (state.hikes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppSearchField(
                        hint: 'Пошук в обраному',
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                  Expanded(
                    child: switch (state.status) {
                      FavoritesStatus.loading => const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.accent)),
                      _ when state.hikes.isEmpty => _empty(
                          Icons.favorite_border,
                          'Тут зʼявляться збережені походи'),
                      _ when hikes.isEmpty =>
                        _empty(Icons.search_off, 'Нічого не знайдено'),
                      _ => ListView.separated(
                          itemCount: hikes.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1, color: AppColors.divider),
                          itemBuilder: (context, i) {
                            final hike = hikes[i];
                            return HikeListTile(
                              hike: hike,
                              onTap: () => context.push('/hike', extra: hike),
                              trailing: IconButton(
                                icon: const Icon(Icons.favorite,
                                    color: AppColors.accent),
                                onPressed: () =>
                                    context.read<FavoritesCubit>().toggle(hike),
                              ),
                            );
                          },
                        ),
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _empty(IconData icon, String text) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(text,
                style: GoogleFonts.manrope(color: AppColors.textSecondary)),
          ],
        ),
      );
}
