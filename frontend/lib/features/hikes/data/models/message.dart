import 'profile_ref.dart';

/// The kind of a chat message payload.
enum MessageKind { text, image, file, contact }

MessageKind _kindFrom(String? v) => switch (v) {
      'image' => MessageKind.image,
      'file' => MessageKind.file,
      'contact' => MessageKind.contact,
      _ => MessageKind.text,
    };

/// A per-hike chat message (messages row, with embedded sender).
class Message {
  const Message({
    required this.id,
    required this.hikeId,
    required this.senderId,
    required this.body,
    required this.createdAt,
    this.kind = MessageKind.text,
    this.attachmentUrl,
    this.attachmentName,
    this.meta,
    this.sender,
  });

  final String id;
  final String hikeId;
  final String senderId;
  final String body;
  final DateTime createdAt;
  final MessageKind kind;
  final String? attachmentUrl;
  final String? attachmentName;
  final Map<String, dynamic>? meta;
  final ProfileRef? sender;

  /// Shared-contact fields (kind == contact) live in [meta].
  String? get contactName => meta?['name'] as String?;
  String? get contactHandle => meta?['handle'] as String?;

  factory Message.fromMap(Map<String, dynamic> map) {
    final s = map['sender'];
    return Message(
      id: map['id'] as String,
      hikeId: map['hike_id'] as String,
      senderId: map['sender_id'] as String,
      body: (map['body'] as String?) ?? '',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime(2000),
      kind: _kindFrom(map['kind'] as String?),
      attachmentUrl: map['attachment_url'] as String?,
      attachmentName: map['attachment_name'] as String?,
      meta: (map['meta'] as Map?)?.cast<String, dynamic>(),
      sender: s is Map<String, dynamic> ? ProfileRef.fromMap(s) : null,
    );
  }
}
