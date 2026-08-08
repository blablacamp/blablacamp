import 'package:blablacamp/core/utils/date_format.dart';
import 'package:blablacamp/features/hikes/data/models/hike.dart';
import 'package:blablacamp/features/hikes/data/models/profile_ref.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Hike.fromMap', () {
    test('parses fields, type and free/price', () {
      final hike = Hike.fromMap({
        'id': 'h1',
        'type': 'guided',
        'title': 'Говерла',
        'price_cents': 240000,
        'duration_days': 3,
        'difficulty': 'hard',
        'start_date': '2026-08-22',
        'end_date': '2026-08-24',
        'includes': ['Трансфер', 'Ночівля'],
        'organizer': {'id': 'o1', 'display_name': 'Олена Гірська'},
      });
      expect(hike.type, HikeType.guided);
      expect(hike.isFree, isFalse);
      expect(hike.priceLabel.replaceAll(RegExp(r'\s'), ''), '2400₴');
      expect(hike.difficulty, HikeDifficulty.hard);
      expect(hike.durationDays, 3);
      expect(hike.includes, contains('Ночівля'));
      expect(hike.organizer.displayName, 'Олена Гірська');
    });

    test('shared hike is free', () {
      final hike = Hike.fromMap({
        'id': 'h2',
        'type': 'shared',
        'title': 'Боржава',
        'price_cents': 0,
        'organizer': {'id': 'o2', 'display_name': 'Олег'},
      });
      expect(hike.type, HikeType.shared);
      expect(hike.isFree, isTrue);
      expect(hike.priceLabel, 'Безкоштовно');
    });
  });

  group('ProfileRef.initials', () {
    test('two-word name', () {
      expect(const ProfileRef(id: '1', displayName: 'Олена Гірська').initials,
          'ОГ');
    });
    test('single word', () {
      expect(const ProfileRef(id: '1', displayName: 'Тарас').initials, 'Т');
    });
    test('empty', () {
      expect(const ProfileRef(id: '1', displayName: '').initials, '?');
    });
  });

  group('formatDateRange', () {
    test('same month', () {
      expect(formatDateRange(DateTime(2026, 8, 14), DateTime(2026, 8, 18)),
          '14–18 серпня');
    });
    test('cross month', () {
      expect(formatDateRange(DateTime(2026, 7, 30), DateTime(2026, 8, 2)),
          '30 липня – 2 серпня');
    });
    test('null bounds', () {
      expect(formatDateRange(null, null), 'Дати уточнюються');
    });
  });
}
