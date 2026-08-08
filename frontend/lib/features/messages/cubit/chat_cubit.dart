import 'dart:async';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
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
    this.typingName,
  });

  final ChatStatus status;
  final List<Message> messages;
  final bool sending;

  /// Name of another member currently typing, or null.
  final String? typingName;

  ChatState copyWith({
    ChatStatus? status,
    List<Message>? messages,
    bool? sending,
    String? typingName,
    bool clearTyping = false,
  }) =>
      ChatState(
        status: status ?? this.status,
        messages: messages ?? this.messages,
        sending: sending ?? this.sending,
        typingName: clearTyping ? null : (typingName ?? this.typingName),
      );

  @override
  List<Object?> get props => [status, messages, sending, typingName];
}

class ChatCubit extends Cubit<ChatState> {
  ChatCubit(this._repo, {required this.hikeId}) : super(const ChatState()) {
    load();
    // Live updates + a "typing" ping from other members.
    _channel = _repo.subscribeToMessages(hikeId, load, onTyping: _onTyping);
    // Coming back to the app (or after a network drop) can miss realtime
    // events — pull the latest messages on resume to stay in sync.
    _lifecycle = AppLifecycleListener(onResume: load);
  }

  final HikesRepository _repo;
  final String hikeId;
  RealtimeChannel? _channel;
  late final AppLifecycleListener _lifecycle;
  Timer? _typingClear;
  DateTime? _lastTypingSent;

  Future<void> load() async {
    if (state.messages.isEmpty) emit(state.copyWith(status: ChatStatus.loading));
    try {
      final msgs = await _repo.fetchMessages(hikeId);
      emit(state.copyWith(status: ChatStatus.ready, messages: msgs));
    } catch (_) {
      if (state.messages.isEmpty) emit(state.copyWith(status: ChatStatus.error));
    }
  }

  void _onTyping(String name) {
    emit(state.copyWith(typingName: name));
    _typingClear?.cancel();
    _typingClear = Timer(const Duration(seconds: 3),
        () => emit(state.copyWith(clearTyping: true)));
  }

  /// Throttled: tells other members we're typing (at most every ~2s).
  void notifyTyping() {
    final channel = _channel;
    if (channel == null) return;
    final now = DateTime.now();
    if (_lastTypingSent != null &&
        now.difference(_lastTypingSent!) < const Duration(seconds: 2)) {
      return;
    }
    _lastTypingSent = now;
    _repo.broadcastTyping(channel);
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

  Future<void> sendAttachment({
    required Uint8List bytes,
    required String filename,
    required bool isImage,
    String? contentType,
  }) async {
    if (state.sending) return;
    emit(state.copyWith(sending: true));
    try {
      final url = await _repo.uploadChatAttachment(hikeId, bytes, filename,
          contentType: contentType);
      await _repo.sendAttachmentMessage(
        hikeId,
        kind: isImage ? 'image' : 'file',
        attachmentUrl: url,
        attachmentName: filename,
      );
      final msgs = await _repo.fetchMessages(hikeId);
      emit(state.copyWith(sending: false, messages: msgs));
    } catch (_) {
      emit(state.copyWith(sending: false));
    }
  }

  Future<void> sendContact(String name, String handle) async {
    if (state.sending) return;
    emit(state.copyWith(sending: true));
    try {
      await _repo.sendContactMessage(hikeId, name: name, handle: handle);
      final msgs = await _repo.fetchMessages(hikeId);
      emit(state.copyWith(sending: false, messages: msgs));
    } catch (_) {
      emit(state.copyWith(sending: false));
    }
  }

  @override
  Future<void> close() {
    _typingClear?.cancel();
    _lifecycle.dispose();
    final channel = _channel;
    if (channel != null) _repo.unsubscribe(channel);
    return super.close();
  }
}
