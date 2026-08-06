import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logging/app_logger.dart';
import '../../hikes/data/hikes_repository.dart';
import '../../hikes/data/models/hike.dart';

enum FavoritesStatus { loading, ready, error }

class FavoritesState extends Equatable {
  const FavoritesState({
    this.status = FavoritesStatus.loading,
    this.hikes = const [],
    this.ids = const {},
  });

  final FavoritesStatus status;
  final List<Hike> hikes;
  final Set<String> ids;

  bool isFavorite(String hikeId) => ids.contains(hikeId);

  FavoritesState copyWith({
    FavoritesStatus? status,
    List<Hike>? hikes,
    Set<String>? ids,
  }) =>
      FavoritesState(
        status: status ?? this.status,
        hikes: hikes ?? this.hikes,
        ids: ids ?? this.ids,
      );

  @override
  List<Object?> get props => [status, hikes, ids];
}

/// App-level favorites state, shared by the "Обране" tab and the hike-details
/// heart, so a like reflects everywhere instantly.
class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit(this._repo) : super(const FavoritesState()) {
    load();
  }

  final HikesRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(status: FavoritesStatus.loading));
    try {
      final hikes = await _repo.fetchFavoriteHikes();
      emit(state.copyWith(
        status: FavoritesStatus.ready,
        hikes: hikes,
        ids: hikes.map((h) => h.id).toSet(),
      ));
    } catch (e, s) {
      AppLog.I.error('favorites', 'load failed', error: e, stackTrace: s);
      emit(state.copyWith(status: FavoritesStatus.error));
    }
  }

  /// Optimistically flips the favorite state and persists it.
  Future<void> toggle(Hike hike) async {
    final wasFav = state.ids.contains(hike.id);
    final ids = {...state.ids};
    final hikes = [...state.hikes];
    if (wasFav) {
      ids.remove(hike.id);
      hikes.removeWhere((h) => h.id == hike.id);
    } else {
      ids.add(hike.id);
      hikes.insert(0, hike);
    }
    emit(state.copyWith(ids: ids, hikes: hikes));
    try {
      await _repo.toggleFavorite(hike.id);
    } catch (e, s) {
      AppLog.I.error('favorites', 'toggle failed', error: e, stackTrace: s);
      // Revert on failure.
      await load();
    }
  }
}
