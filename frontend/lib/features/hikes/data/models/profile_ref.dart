/// Lightweight reference to a user (organizer / participant) as embedded in
/// hike queries. The full profile lives in the `profiles` table.
class ProfileRef {
  const ProfileRef({
    required this.id,
    required this.displayName,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final String? avatarUrl;

  factory ProfileRef.fromMap(Map<String, dynamic> map) => ProfileRef(
        id: map['id'] as String,
        displayName: (map['display_name'] as String?) ?? '',
        avatarUrl: map['avatar_url'] as String?,
      );

  /// First letters for avatar fallback, e.g. "Олена Гірська" -> "ОГ".
  String get initials {
    final parts =
        displayName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    final first = parts.first.substring(0, 1);
    final second = parts.length > 1 ? parts.elementAt(1).substring(0, 1) : '';
    return (first + second).toUpperCase();
  }
}
