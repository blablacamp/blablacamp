import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../hikes/data/hikes_repository.dart';
import '../../hikes/data/models/checklist_item.dart';
import '../../hikes/data/models/hike.dart';

enum BackpackStatus { loading, ready, error }

class BackpackState extends Equatable {
  const BackpackState({
    this.status = BackpackStatus.loading,
    this.hike,
    this.items = const [],
  });

  final BackpackStatus status;
  final Hike? hike;
  final List<ChecklistItem> items;

  Map<String, List<ChecklistItem>> get byCategory {
    final map = <String, List<ChecklistItem>>{};
    for (final item in items) {
      map.putIfAbsent(item.category, () => []).add(item);
    }
    return map;
  }

  List<ChecklistItem> get missing =>
      items.where((i) => i.status != ChecklistStatus.packed).toList();

  int get packedCount =>
      items.where((i) => i.status == ChecklistStatus.packed).length;

  BackpackState copyWith({
    BackpackStatus? status,
    Hike? hike,
    List<ChecklistItem>? items,
  }) =>
      BackpackState(
        status: status ?? this.status,
        hike: hike ?? this.hike,
        items: items ?? this.items,
      );

  @override
  List<Object?> get props => [status, hike, items];
}

class BackpackCubit extends Cubit<BackpackState> {
  BackpackCubit(this._repo) : super(const BackpackState()) {
    load();
  }

  final HikesRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(status: BackpackStatus.loading));
    try {
      final hike = await _repo.fetchMyCurrentHike();
      if (hike == null) {
        emit(const BackpackState(status: BackpackStatus.ready));
        return;
      }
      await _repo.ensureChecklist(hike.id);
      final items = await _repo.fetchChecklist(hike.id);
      emit(BackpackState(
          status: BackpackStatus.ready, hike: hike, items: items));
    } catch (_) {
      emit(state.copyWith(status: BackpackStatus.error));
    }
  }

  /// Toggle whether an item is packed. Optimistic; persists in the background.
  Future<void> toggle(ChecklistItem item) async {
    final next = item.status == ChecklistStatus.packed
        ? ChecklistStatus.todo
        : ChecklistStatus.packed;
    emit(state.copyWith(
      items: state.items
          .map((i) => i.id == item.id ? i.copyWith(status: next) : i)
          .toList(),
    ));
    try {
      await _repo.setChecklistStatus(item.id, next);
    } catch (_) {
      emit(state.copyWith(
        items: state.items
            .map((i) => i.id == item.id ? i.copyWith(status: item.status) : i)
            .toList(),
      ));
    }
  }

  Future<void> addItem({
    required String category,
    required String name,
    String? spec,
  }) async {
    final hike = state.hike;
    if (hike == null) return;
    await _repo.addChecklistItem(
        hikeId: hike.id, category: category, name: name, spec: spec);
    await load();
  }
}
