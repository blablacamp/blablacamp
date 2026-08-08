import 'package:blablacamp/features/hikes/data/hikes_repository.dart';
import 'package:blablacamp/features/hikes/data/models/hike.dart';
import 'package:blablacamp/features/hikes/data/models/profile_ref.dart';
import 'package:blablacamp/features/home/cubit/home_cubit.dart';
import 'package:blablacamp/features/search/cubit/search_cubit.dart';
import 'package:blablacamp/features/favorites/cubit/favorites_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

// No Supabase client -> repository serves its offline sample data, so these
// cubits can be tested end-to-end without mocks.
void main() {
  final repo = HikesRepository();

  test('HomeCubit loads the gathering feed', () async {
    final cubit = HomeCubit(repo);
    final state =
        await cubit.stream.firstWhere((s) => s.status == HomeStatus.ready);
    expect(state.gathering, isNotEmpty);
    expect(state.recommendation, isNotNull);
    await cubit.close();
  });

  test('SearchCubit filters by query', () async {
    final cubit = SearchCubit(repo);
    await cubit.stream.firstWhere((s) => s.status == SearchStatus.ready);
    cubit.setQuery('Боржава');
    final filtered = await cubit.stream.firstWhere(
        (s) => s.status == SearchStatus.ready && s.query == 'Боржава');
    expect(filtered.hikes, isNotEmpty);
    expect(
      filtered.hikes.every((h) =>
          h.title.toLowerCase().contains('боржава') ||
          (h.region ?? '').toLowerCase().contains('боржава')),
      isTrue,
    );
    await cubit.close();
  });

  test('FavoritesCubit toggles membership', () async {
    final cubit = FavoritesCubit(repo);
    await cubit.stream.firstWhere((s) => s.status == FavoritesStatus.ready);
    const hike = Hike(
      id: 'fav-1',
      type: HikeType.shared,
      title: 'Тест',
      organizer: ProfileRefStub(),
    );
    await cubit.toggle(hike);
    expect(cubit.state.isFavorite('fav-1'), isTrue);
    await cubit.toggle(hike);
    expect(cubit.state.isFavorite('fav-1'), isFalse);
    await cubit.close();
  });
}

// Minimal ProfileRef for constructing a Hike in tests.
class ProfileRefStub extends ProfileRef {
  const ProfileRefStub() : super(id: 's', displayName: 'Stub');
}
