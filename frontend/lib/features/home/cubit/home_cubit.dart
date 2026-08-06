import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logging/app_logger.dart';
import '../../hikes/data/hikes_repository.dart';
import '../../hikes/data/models/hike.dart';

enum HomeStatus { loading, ready, error }

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.loading,
    this.gathering = const [],
    this.error,
  });

  final HomeStatus status;
  final List<Hike> gathering;
  final String? error;

  /// The hike we surface in the "підійде до твого наплічника" recommendation.
  Hike? get recommendation =>
      gathering.where((h) => h.difficulty == HikeDifficulty.easy).firstOrNull ??
      gathering.firstOrNull;

  HomeState copyWith({
    HomeStatus? status,
    List<Hike>? gathering,
    String? error,
  }) =>
      HomeState(
        status: status ?? this.status,
        gathering: gathering ?? this.gathering,
        error: error,
      );

  @override
  List<Object?> get props => [status, gathering, error];
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._repo) : super(const HomeState()) {
    load();
  }

  final HikesRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(status: HomeStatus.loading));
    try {
      final hikes = await _repo.fetchGathering();
      emit(state.copyWith(status: HomeStatus.ready, gathering: hikes));
    } catch (e, s) {
      AppLog.I.error('home', 'load gathering failed', error: e, stackTrace: s);
      emit(state.copyWith(status: HomeStatus.error, error: e.toString()));
    }
  }
}
