import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../hikes/data/hikes_repository.dart';
import '../../hikes/data/models/checklist_item.dart';

enum BackpackStatus { loading, ready, error }

class BackpackState extends Equatable {
  const BackpackState({
    this.status = BackpackStatus.loading,
    this.items = const [],
    this.error,
  });

  final BackpackStatus status;
  final List<ChecklistItem> items;
  final String? error;

  /// Items grouped by category, preserving first-seen order.
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
    List<ChecklistItem>? items,
    String? error,
  }) =>
      BackpackState(
        status: status ?? this.status,
        items: items ?? this.items,
        error: error,
      );

  @override
  List<Object?> get props => [status, items, error];
}

class BackpackCubit extends Cubit<BackpackState> {
  BackpackCubit(this._repo, {required this.hikeId}) : super(const BackpackState()) {
    load();
  }

  final HikesRepository _repo;
  final String hikeId;

  Future<void> load() async {
    emit(state.copyWith(status: BackpackStatus.loading));
    try {
      final items = await _repo.fetchChecklist(hikeId);
      emit(state.copyWith(status: BackpackStatus.ready, items: items));
    } catch (e) {
      emit(state.copyWith(status: BackpackStatus.error, error: e.toString()));
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
      // Revert on failure.
      emit(state.copyWith(
        items: state.items
            .map((i) => i.id == item.id ? i.copyWith(status: item.status) : i)
            .toList(),
      ));
    }
  }
}
