/// Ukrainian date helpers. Kept dependency-free (no intl locale data needed).
const _monthsGenitive = [
  'січня', 'лютого', 'березня', 'квітня', 'травня', 'червня',
  'липня', 'серпня', 'вересня', 'жовтня', 'листопада', 'грудня',
];

/// Formats a start/end range like "14–18 серпня" or "30 липня – 2 серпня".
/// Falls back gracefully when either bound is null.
String formatDateRange(DateTime? start, DateTime? end) {
  if (start == null && end == null) return 'Дати уточнюються';
  if (start != null && end == null) return _day(start);
  if (start == null && end != null) return _day(end);

  final s = start!;
  final e = end!;
  if (s.month == e.month && s.year == e.year) {
    return '${s.day}–${e.day} ${_monthsGenitive[s.month - 1]}';
  }
  return '${_day(s)} – ${_day(e)}';
}

String _day(DateTime d) => '${d.day} ${_monthsGenitive[d.month - 1]}';
