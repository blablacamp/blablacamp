import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logging/app_logger.dart';
import '../../hikes/data/hikes_repository.dart';
import '../../hikes/data/models/hike.dart';

/// null = "Усі"; otherwise filter by a specific hike type.
typedef HikeFilter = HikeType?;

enum SearchStatus { loading, ready, error }

class SearchState extends Equatable {
  const SearchState({
    this.status = SearchStatus.loading,
    this.all = const [],
    this.filter,
    this.query = '',
    this.error,
  });

  final SearchStatus status;
  final List<Hike> all;
  final HikeFilter filter;
  final String query;
  final String? error;

  List<Hike> get visible {
    final q = query.trim().toLowerCase();
    return all.where((h) {
      final matchesType = filter == null || h.type == filter;
      final matchesQuery = q.isEmpty ||
          h.title.toLowerCase().contains(q) ||
          (h.region ?? '').toLowerCase().contains(q) ||
          (h.location ?? '').toLowerCase().contains(q);
      return matchesType && matchesQuery;
    }).toList();
  }

  SearchState copyWith({
    SearchStatus? status,
    List<Hike>? all,
    HikeFilter? filter,
    bool clearFilter = false,
    String? query,
    String? error,
  }) =>
      SearchState(
        status: status ?? this.status,
        all: all ?? this.all,
        filter: clearFilter ? null : (filter ?? this.filter),
        query: query ?? this.query,
        error: error,
      );

  @override
  List<Object?> get props => [status, all, filter, query, error];
}

class SearchCubit extends Cubit<SearchState> {
  SearchCubit(this._repo) : super(const SearchState()) {
    load();
  }

  final HikesRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(status: SearchStatus.loading));
    try {
      final hikes = await _repo.search();
      emit(state.copyWith(status: SearchStatus.ready, all: hikes));
    } catch (e, s) {
      AppLog.I.error('search', 'load failed', error: e, stackTrace: s);
      emit(state.copyWith(status: SearchStatus.error, error: e.toString()));
    }
  }

  void setFilter(HikeFilter filter) {
    if (filter == null) {
      emit(state.copyWith(clearFilter: true));
    } else {
      emit(state.copyWith(filter: filter));
    }
  }

  void setQuery(String query) => emit(state.copyWith(query: query));
}
