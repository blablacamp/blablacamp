import 'package:flutter_bloc/flutter_bloc.dart';

import '../../hikes/data/hikes_repository.dart';

/// App-level unread-conversations count, powering the Повідомлення badge.
class UnreadCubit extends Cubit<int> {
  UnreadCubit(this._repo) : super(0) {
    refresh();
  }

  final HikesRepository _repo;

  Future<void> refresh() async {
    final count = await _repo.fetchUnreadCount();
    if (!isClosed) emit(count);
  }
}
