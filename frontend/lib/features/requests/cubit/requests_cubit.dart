import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../hikes/data/hikes_repository.dart';
import '../../hikes/data/models/join_request.dart';

enum RequestsStatus { loading, ready, error }

class RequestsState extends Equatable {
  const RequestsState({
    this.status = RequestsStatus.loading,
    this.requests = const [],
  });

  final RequestsStatus status;
  final List<JoinRequest> requests;

  RequestsState copyWith({RequestsStatus? status, List<JoinRequest>? requests}) =>
      RequestsState(
        status: status ?? this.status,
        requests: requests ?? this.requests,
      );

  @override
  List<Object?> get props => [status, requests];
}

class RequestsCubit extends Cubit<RequestsState> {
  RequestsCubit(this._repo) : super(const RequestsState()) {
    load();
  }

  final HikesRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(status: RequestsStatus.loading));
    try {
      final reqs = await _repo.fetchIncomingRequests();
      emit(state.copyWith(status: RequestsStatus.ready, requests: reqs));
    } catch (_) {
      emit(state.copyWith(status: RequestsStatus.error));
    }
  }

  /// Optimistically remove the request from the list and persist the decision.
  Future<void> respond(JoinRequest request, bool approve) async {
    emit(state.copyWith(
      requests: state.requests.where((r) => r.id != request.id).toList(),
    ));
    try {
      await _repo.respondToRequest(request: request, approve: approve);
    } catch (_) {
      await load(); // revert to server truth on failure
    }
  }
}
