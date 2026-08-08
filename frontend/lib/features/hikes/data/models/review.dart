import 'profile_ref.dart';

/// A rating a member left about another member after a hike.
class Review {
  const Review({
    required this.id,
    required this.rating,
    required this.createdAt,
    this.body,
    this.author,
  });

  final String id;
  final int rating;
  final String? body;
  final DateTime createdAt;
  final ProfileRef? author;

  factory Review.fromMap(Map<String, dynamic> map) {
    final a = map['author'];
    return Review(
      id: map['id'] as String,
      rating: (map['rating'] as int?) ?? 0,
      body: map['body'] as String?,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime(2000),
      author: a is Map<String, dynamic> ? ProfileRef.fromMap(a) : null,
    );
  }
}
