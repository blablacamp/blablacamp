import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../hikes/data/hikes_repository.dart';
import '../../hikes/data/models/hike.dart';

enum ConversationsStatus { loading, ready, error }

class ConversationsState extends Equatable {
  const ConversationsState(
      {this.status = ConversationsStatus.loading, this.hikes = const []});

  final ConversationsStatus status;
  final List<Hike> hikes;

  ConversationsState copyWith({ConversationsStatus? status, List<Hike>? hikes}) =>
      ConversationsState(
          status: status ?? this.status, hikes: hikes ?? this.hikes);

  @override
  List<Object?> get props => [status, hikes];
}

/// Conversation list = hikes the user is an approved member of.
class ConversationsCubit extends Cubit<ConversationsState> {
  ConversationsCubit(this._repo) : super(const ConversationsState()) {
    load();
  }

  final HikesRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(status: ConversationsStatus.loading));
    try {
      final hikes = await _repo.fetchMemberHikes();
      emit(state.copyWith(status: ConversationsStatus.ready, hikes: hikes));
    } catch (_) {
      emit(state.copyWith(status: ConversationsStatus.error));
    }
  }
}
