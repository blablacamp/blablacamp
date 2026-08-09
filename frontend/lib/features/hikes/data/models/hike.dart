import 'profile_ref.dart';

enum HikeType {
  guided,
  shared;

  static HikeType fromValue(String? v) =>
      v == 'guided' ? HikeType.guided : HikeType.shared;

  String get label => this == HikeType.guided ? 'З гідом' : 'Спільний';
}

enum HikeDifficulty {
  easy,
  moderate,
  hard,
  expert;

  static HikeDifficulty fromValue(String? v) => switch (v) {
        'easy' => HikeDifficulty.easy,
        'hard' => HikeDifficulty.hard,
        'expert' => HikeDifficulty.expert,
        _ => HikeDifficulty.moderate,
      };

  String get label => switch (this) {
        HikeDifficulty.easy => 'легкий',
        HikeDifficulty.moderate => 'середній',
        HikeDifficulty.hard => 'складний',
        HikeDifficulty.expert => 'експертний',
      };
}

/// A hike listing, mirroring the `hikes` table (+ embedded organizer).
class Hike {
  const Hike({
    required this.id,
    required this.type,
    required this.title,
    required this.organizer,
    this.summary,
    this.description,
    this.legend,
    this.coverUrl,
    this.region,
    this.location,
    this.startDate,
    this.endDate,
    this.difficulty = HikeDifficulty.moderate,
    this.distanceKm,
    this.durationDays = 1,
    this.maxParticipants = 8,
    this.priceCents = 0,
    this.currency = 'UAH',
    this.includes = const [],
    this.highlights = const [],
  });

  final String id;
  final HikeType type;
  final String title;
  final ProfileRef organizer;
  final String? summary;
  final String? description;

  /// A short Carpathian legend / lore about this place (Галицька фішка).
  final String? legend;
  final String? coverUrl;
  final String? region;
  final String? location;
  final DateTime? startDate;
  final DateTime? endDate;
  final HikeDifficulty difficulty;
  final double? distanceKm;
  final int durationDays;
  final int maxParticipants;
  final int priceCents;
  final String currency;
  final List<String> includes;
  final List<String> highlights;

  bool get isFree => priceCents == 0;

  /// Price like "2 400 ₴" (only meaningful for guided hikes).
  String get priceLabel {
    if (isFree) return 'Безкоштовно';
    final whole = (priceCents / 100).round();
    final s = whole.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '$buf ₴';
  }

  factory Hike.fromMap(Map<String, dynamic> map) {
    final org = map['organizer'];
    return Hike(
      id: map['id'] as String,
      type: HikeType.fromValue(map['type'] as String?),
      title: (map['title'] as String?) ?? '',
      summary: map['summary'] as String?,
      description: map['description'] as String?,
      legend: map['legend'] as String?,
      coverUrl: map['cover_url'] as String?,
      region: map['region'] as String?,
      location: map['location'] as String?,
      startDate: _date(map['start_date']),
      endDate: _date(map['end_date']),
      difficulty: HikeDifficulty.fromValue(map['difficulty'] as String?),
      distanceKm: (map['distance_km'] as num?)?.toDouble(),
      durationDays: (map['duration_days'] as int?) ?? 1,
      maxParticipants: (map['max_participants'] as int?) ?? 8,
      priceCents: (map['price_cents'] as int?) ?? 0,
      currency: (map['currency'] as String?) ?? 'UAH',
      includes: (map['includes'] as List?)?.cast<String>() ?? const [],
      highlights: (map['highlights'] as List?)?.cast<String>() ?? const [],
      organizer: org is Map<String, dynamic>
          ? ProfileRef.fromMap(org)
          : const ProfileRef(id: '', displayName: ''),
    );
  }

  static DateTime? _date(Object? v) =>
      v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;
}
