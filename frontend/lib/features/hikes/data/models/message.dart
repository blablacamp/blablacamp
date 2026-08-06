import 'profile_ref.dart';

/// A per-hike chat message (messages row, with embedded sender).
class Message {
  const Message({
    required this.id,
    required this.hikeId,
    required this.senderId,
    required this.body,
    required this.createdAt,
    this.sender,
  });

  final String id;
  final String hikeId;
  final String senderId;
  final String body;
  final DateTime createdAt;
  final ProfileRef? sender;

  factory Message.fromMap(Map<String, dynamic> map) {
    final s = map['sender'];
    return Message(
      id: map['id'] as String,
      hikeId: map['hike_id'] as String,
      senderId: map['sender_id'] as String,
      body: (map['body'] as String?) ?? '',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime(2000),
      sender: s is Map<String, dynamic> ? ProfileRef.fromMap(s) : null,
    );
  }
}
