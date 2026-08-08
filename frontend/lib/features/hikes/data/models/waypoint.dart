/// A point on a hike's route (ordered by [seq]).
class Waypoint {
  const Waypoint({
    required this.seq,
    required this.name,
    required this.lat,
    required this.lng,
  });

  final int seq;
  final String name;
  final double lat;
  final double lng;

  factory Waypoint.fromMap(Map<String, dynamic> map) => Waypoint(
        seq: (map['seq'] as num?)?.toInt() ?? 0,
        name: (map['name'] as String?) ?? '',
        lat: (map['lat'] as num).toDouble(),
        lng: (map['lng'] as num).toDouble(),
      );
}
