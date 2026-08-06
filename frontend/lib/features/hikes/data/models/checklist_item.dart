/// Status of a gear item in the "backpack" checklist.
/// Mirrors checklist_items.status (todo | packed | shared) with UI affordances.
enum ChecklistStatus {
  packed, // "Є" — you have it
  shared, // "Позичити" — coming from another member
  todo; // needs action (rent / buy / pack)

  static ChecklistStatus fromValue(String? v) => switch (v) {
        'packed' => ChecklistStatus.packed,
        'shared' => ChecklistStatus.shared,
        _ => ChecklistStatus.todo,
      };

  String get value => switch (this) {
        ChecklistStatus.packed => 'packed',
        ChecklistStatus.shared => 'shared',
        ChecklistStatus.todo => 'todo',
      };
}

class ChecklistItem {
  const ChecklistItem({
    required this.id,
    required this.category,
    required this.name,
    required this.status,
    this.spec,
    this.actionLabel,
    this.actionNote,
  });

  final String id;
  final String category;
  final String name;
  final ChecklistStatus status;
  final String? spec;

  /// Call-to-action shown for a `todo`/`shared` item, e.g. "Орендувати",
  /// "Купити", "Позичити". Presentational; not persisted.
  final String? actionLabel;

  /// Small note next to a shared item, e.g. "у Марти".
  final String? actionNote;

  ChecklistItem copyWith({ChecklistStatus? status}) => ChecklistItem(
        id: id,
        category: category,
        name: name,
        status: status ?? this.status,
        spec: spec,
        actionLabel: actionLabel,
        actionNote: actionNote,
      );

  factory ChecklistItem.fromMap(Map<String, dynamic> map) => ChecklistItem(
        id: map['id'] as String,
        category: (map['category'] as String?) ?? 'Інше',
        name: (map['name'] as String?) ?? '',
        spec: map['spec'] as String?,
        status: ChecklistStatus.fromValue(map['status'] as String?),
      );
}
