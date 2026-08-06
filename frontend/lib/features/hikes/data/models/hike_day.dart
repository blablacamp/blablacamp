/// One day of a hike's itinerary (hike_itinerary row).
class HikeDay {
  const HikeDay({
    required this.dayNum,
    required this.title,
    this.description,
  });

  final int dayNum;
  final String title;
  final String? description;

  factory HikeDay.fromMap(Map<String, dynamic> map) => HikeDay(
        dayNum: (map['day_num'] as int?) ?? 0,
        title: (map['title'] as String?) ?? '',
        description: map['description'] as String?,
      );
}
