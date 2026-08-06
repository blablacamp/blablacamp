import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../hikes/data/hikes_repository.dart';
import '../../hikes/data/models/message.dart';

enum ChatStatus { loading, ready, error }

class ChatState extends Equatable {
  const ChatState({
    this.status = ChatStatus.loading,
    this.messages = const [],
    this.sending = false,
  });

  final ChatStatus status;
  final List<Message> messages;
  final bool sending;

  ChatState copyWith({
    ChatStatus? status,
    List<Message>? messages,
    bool? sending,
  }) =>
      ChatState(
        status: status ?? this.status,
        messages: messages ?? this.messages,
        sending: sending ?? this.sending,
      );

  @override
  List<Object?> get props => [status, messages, sending];
}

class ChatCubit extends Cubit<ChatState> {
  ChatCubit(this._repo, {required this.hikeId}) : super(const ChatState()) {
    load();
    // Live updates: refetch (with sender join) whenever a message lands.
    _channel = _repo.subscribeToMessages(hikeId, load);
  }

  final HikesRepository _repo;
  final String hikeId;
  RealtimeChannel? _channel;

  Future<void> load() async {
    emit(state.copyWith(status: ChatStatus.loading));
    try {
      final msgs = await _repo.fetchMessages(hikeId);
      emit(state.copyWith(status: ChatStatus.ready, messages: msgs));
    } catch (_) {
      emit(state.copyWith(status: ChatStatus.error));
    }
  }

  Future<void> send(String body) async {
    final text = body.trim();
    if (text.isEmpty || state.sending) return;
    emit(state.copyWith(sending: true));
    try {
      await _repo.sendMessage(hikeId, text);
      final msgs = await _repo.fetchMessages(hikeId);
      emit(state.copyWith(sending: false, messages: msgs));
    } catch (_) {
      emit(state.copyWith(sending: false));
    }
  }

  @override
  Future<void> close() {
    final channel = _channel;
    if (channel != null) _repo.unsubscribe(channel);
    return super.close();
  }
}
