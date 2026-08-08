import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logging/app_logger.dart';
import '../../hikes/data/hikes_repository.dart';
import '../../hikes/data/models/hike.dart';

/// null = "Усі"; otherwise filter by a specific hike type.
typedef HikeFilter = HikeType?;

enum SearchStatus { loading, ready, error }

const _pageSize = 20;

class SearchState extends Equatable {
  const SearchState({
    this.status = SearchStatus.loading,
    this.hikes = const [],
    this.filter,
    this.query = '',
    this.hasMore = false,
    this.loadingMore = false,
  });

  final SearchStatus status;
  final List<Hike> hikes;
  final HikeFilter filter;
  final String query;
  final bool hasMore;
  final bool loadingMore;

  SearchState copyWith({
    SearchStatus? status,
    List<Hike>? hikes,
    HikeFilter? filter,
    bool clearFilter = false,
    String? query,
    bool? hasMore,
    bool? loadingMore,
  }) =>
      SearchState(
        status: status ?? this.status,
        hikes: hikes ?? this.hikes,
        filter: clearFilter ? null : (filter ?? this.filter),
        query: query ?? this.query,
        hasMore: hasMore ?? this.hasMore,
        loadingMore: loadingMore ?? this.loadingMore,
      );

  @override
  List<Object?> get props =>
      [status, hikes, filter, query, hasMore, loadingMore];
}

class SearchCubit extends Cubit<SearchState> {
  SearchCubit(this._repo) : super(const SearchState()) {
    _fetch(reset: true);
  }

  final HikesRepository _repo;
  Timer? _debounce;

  Future<void> _fetch({required bool reset}) async {
    if (reset) {
      emit(state.copyWith(status: SearchStatus.loading));
    } else {
      emit(state.copyWith(loadingMore: true));
    }
    try {
      final offset = reset ? 0 : state.hikes.length;
      final page = await _repo.search(
        type: state.filter,
        query: state.query,
        limit: _pageSize,
        offset: offset,
      );
      final hikes = reset ? page : [...state.hikes, ...page];
      emit(state.copyWith(
        status: SearchStatus.ready,
        hikes: hikes,
        hasMore: page.length == _pageSize,
        loadingMore: false,
      ));
    } catch (e, s) {
      AppLog.I.error('search', 'load failed', error: e, stackTrace: s);
      emit(state.copyWith(status: SearchStatus.error, loadingMore: false));
    }
  }

  void setFilter(HikeFilter filter) {
    emit(filter == null
        ? state.copyWith(clearFilter: true)
        : state.copyWith(filter: filter));
    _fetch(reset: true);
  }

  void setQuery(String query) {
    emit(state.copyWith(query: query));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _fetch(reset: true);
    });
  }

  void loadMore() {
    if (state.loadingMore || !state.hasMore) return;
    _fetch(reset: false);
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
