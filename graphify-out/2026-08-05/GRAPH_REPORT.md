# Graph Report - blablacamp  (2026-08-05)

## Corpus Check
- 50 files · ~325,454 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 534 nodes · 717 edges · 47 communities (35 shown, 12 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- home_page.dart
- auth_page.dart
- home_shell.dart
- app_colors.dart
- home_cubit.dart
- AppDelegate
- hike.dart
- app_shapes.dart
- Blablacamp
- hikes_repository.dart
- app.dart
- widget_test.dart
- MainActivity
- blablacamp
- LaunchImage.imageset/README.md
- 20260805120100_functions_triggers.sql
- 20260805120000_init_schema.sql
- public.hike_participants
- public.hikes
- public.checklist_items
- public.favorites
- public.hike_itinerary
- public.messages
- public.profiles
- search_page.dart
- app_router.dart
- index.ts
- date_format.dart
- backpack_page.dart
- onboarding_page.dart
- checklist_item.dart
- hike_details_page.dart
- StatelessWidget
- HikesRepository
- run.sh
- backpack_cubit.dart
- search_cubit.dart
- onboarding_cubit.dart
- String?
- Equatable
- @example

## God Nodes (most connected - your core abstractions)
1. `HikesRepository` - 17 edges
2. `AuthRepository` - 9 edges
3. `OnboardingCubit` - 8 edges
4. `public.profiles` - 7 edges
5. `public.hikes` - 7 edges
6. `AuthCubit` - 7 edges
7. `BackpackCubit` - 6 edges
8. `HomeCubit` - 6 edges
9. `SearchCubit` - 6 edges
10. `Blablacamp` - 6 edges

## Surprising Connections (you probably didn't know these)
- `_AuthViewState` --references--> `AuthCubit`  [EXTRACTED]
  frontend/lib/features/auth/view/auth_page.dart → frontend/lib/features/auth/cubit/auth_cubit.dart
- `_submit` --references--> `AuthCubit`  [EXTRACTED]
  frontend/lib/features/auth/view/auth_page.dart → frontend/lib/features/auth/cubit/auth_cubit.dart
- `build` --references--> `AuthRepository`  [EXTRACTED]
  frontend/lib/features/profile/view/profile_page.dart → frontend/lib/features/auth/data/auth_repository.dart
- `build` --references--> `HikesRepository`  [EXTRACTED]
  frontend/lib/features/backpack/view/backpack_page.dart → frontend/lib/features/hikes/data/hikes_repository.dart
- `_HikeDetailsPageState` --references--> `HikesRepository`  [EXTRACTED]
  frontend/lib/features/hikes/view/hike_details_page.dart → frontend/lib/features/hikes/data/hikes_repository.dart

## Import Cycles
- None detected.

## Communities (47 total, 12 thin omitted)

### Community 0 - "home_page.dart"
Cohesion: 0.12
Nodes (18): ../../../core/utils/date_format.dart, ../cubit/home_cubit.dart, HomeCubit, HomeState, build, _ConsoleDivider, _ConsoleField, _GatheringCard (+10 more)

### Community 1 - "auth_page.dart"
Cohesion: 0.06
Nodes (43): ../../auth/data/auth_repository.dart, ../../core/theme/app_colors.dart, ../../../core/theme/app_shapes.dart, ../cubit/auth_cubit.dart, ../data/auth_repository.dart, FormState, AuthCubit, AuthFormState (+35 more)

### Community 2 - "home_shell.dart"
Cohesion: 0.10
Nodes (21): ../backpack/view/backpack_page.dart, _AuthView, _AuthViewState, HikeDetailsPage, _HikeDetailsPageState, createState, HomeShell, _HomeShellState (+13 more)

### Community 3 - "app_colors.dart"
Cohesion: 0.09
Nodes (21): Env, hasOneSignal, hasSupabase, oneSignalAppId, supabaseAnonKey, supabaseUrl, accent, accentPressed (+13 more)

### Community 4 - "home_cubit.dart"
Cohesion: 0.15
Nodes (12): copyWith, error, gathering, HomeStatus, load, props, recommendation, _repo (+4 more)

### Community 5 - "AppDelegate"
Cohesion: 0.11
Nodes (14): Any, Bool, Flutter, FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, FlutterSceneDelegate, AppDelegate (+6 more)

### Community 6 - "hike.dart"
Cohesion: 0.05
Nodes (42): BorderRadius?, DateTime?, double?, easy,
  moderate,
  hard,, ../../features/hikes/data/models/hike.dart, borderRadius, build, _fallbacks (+34 more)

### Community 7 - "app_shapes.dart"
Cohesion: 0.22
Nodes (8): AppShapes, _large, leaf, leafOf, _small, package:flutter/widgets.dart, static const BorderRadius, static const double

### Community 8 - "Blablacamp"
Cohesion: 0.20
Nodes (9): Backend (Supabase), Blablacamp, Domain in one paragraph, Frontend (Flutter), Link the cloud project (one-time), Notifications (OneSignal), Or run fully local (needs Docker running), Push schema + seed (+1 more)

### Community 9 - "hikes_repository.dart"
Cohesion: 0.10
Nodes (19): _andrii, _client, fetchById, fetchChecklist, fetchGathering, _marta, _oleg, _organizerSelect (+11 more)

### Community 10 - "app.dart"
Cohesion: 0.06
Nodes (36): app.dart, bool get, core/config/env.dart, core/notifications/notifications_service.dart, core/router/app_router.dart, core/theme/app_theme.dart, features/auth/data/auth_repository.dart, features/hikes/data/hikes_repository.dart (+28 more)

### Community 11 - "widget_test.dart"
Cohesion: 0.25
Nodes (7): main, package:blablacamp/app.dart, package:blablacamp/core/notifications/notifications_service.dart, package:blablacamp/core/router/app_router.dart, package:blablacamp/features/auth/data/auth_repository.dart, package:blablacamp/features/hikes/data/hikes_repository.dart, package:flutter_test/flutter_test.dart

### Community 19 - "20260805120100_functions_triggers.sql"
Cohesion: 0.14
Nodes (12): hike_participants_set_updated_at, hikes_set_updated_at, on_auth_user_created, on_hike_created, profiles_set_updated_at, public.is_hike_member(), public.is_hike_organizer(), public.hike_participants (+4 more)

### Community 20 - "20260805120000_init_schema.sql"
Cohesion: 0.50
Nodes (8): auth.users, public.checklist_items, public.favorites, public.hike_itinerary, public.hike_participants, public.hikes, public.messages, public.profiles

### Community 30 - "search_page.dart"
Cohesion: 0.12
Nodes (18): ../../../core/widgets/avatar_circle.dart, ../../../core/widgets/hike_cover.dart, ../cubit/search_cubit.dart, SearchCubit, active, build, _FeaturedCard, _FilterRow (+10 more)

### Community 31 - "app_router.dart"
Cohesion: 0.07
Nodes (26): ChangeNotifier, ../config/env.dart, dart:async, ../../features/auth/view/auth_page.dart, ../../features/hikes/view/hike_details_page.dart, ../../features/onboarding/view/onboarding_page.dart, ../../features/search/view/search_page.dart, ../../features/shell/home_shell.dart (+18 more)

### Community 32 - "index.ts"
Cohesion: 0.33
Nodes (4): corsHeaders, NotifyBody, ONESIGNAL_APP_ID, ONESIGNAL_REST_API_KEY

### Community 33 - "date_format.dart"
Cohesion: 0.33
Nodes (5): _day, e, formatDateRange, _monthsGenitive, s

### Community 34 - "backpack_page.dart"
Cohesion: 0.09
Nodes (23): Color, Cubit, ../cubit/backpack_cubit.dart, BackpackCubit, _amber, _BackpackView, _blue, build (+15 more)

### Community 35 - "onboarding_page.dart"
Cohesion: 0.08
Nodes (28): app_colors.dart, ../cubit/onboarding_cubit.dart, ../../features/hikes/data/models/profile_ref.dart, AppTheme, light, AvatarCircle, build, _initials (+20 more)

### Community 36 - "checklist_item.dart"
Cohesion: 0.12
Nodes (16): actionLabel, actionNote, category, ChecklistItem, ChecklistStatus, copyWith, fromMap, fromValue (+8 more)

### Community 37 - "hike_details_page.dart"
Cohesion: 0.12
Nodes (15): ../data/hikes_repository.dart, ../data/models/hike.dart, build, _CircleButton, createState, hike, icon, _joining (+7 more)

### Community 38 - "StatelessWidget"
Cohesion: 0.17
Nodes (12): _Category, _FriendlyMessage, _Hero, _ItemRow, _NextActions, _ProgressStrip, _StatusChip, _StickyBar (+4 more)

### Community 39 - "HikesRepository"
Cohesion: 0.40
Nodes (5): BackpackPage, HikesRepository, _join, HomePage, SearchPage

### Community 41 - "backpack_cubit.dart"
Cohesion: 0.13
Nodes (14): BackpackStatus, copyWith, error, hikeId, items, load, missing, packedCount (+6 more)

### Community 42 - "search_cubit.dart"
Cohesion: 0.15
Nodes (12): all, copyWith, error, filter, load, props, _repo, SearchStatus (+4 more)

### Community 43 - "onboarding_cubit.dart"
Cohesion: 0.22
Nodes (8): copyWith, props, selectedRole, selectRole, UserRole, value, List, package:equatable/equatable.dart

### Community 44 - "String?"
Cohesion: 0.29
Nodes (6): avatarUrl, displayName, fromMap, id, ProfileRef, String?

### Community 45 - "Equatable"
Cohesion: 0.50
Nodes (4): Equatable, BackpackState, OnboardingState, SearchState

## Knowledge Gaps
- **254 isolated node(s):** `ONESIGNAL_APP_ID`, `ONESIGNAL_REST_API_KEY`, `corsHeaders`, `NotifyBody`, `XCTest` (+249 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **12 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `HikesRepository` connect `HikesRepository` to `home_page.dart`, `backpack_page.dart`, `home_shell.dart`, `home_cubit.dart`, `hike_details_page.dart`, `backpack_cubit.dart`, `app.dart`, `hikes_repository.dart`, `search_cubit.dart`, `search_page.dart`?**
  _High betweenness centrality (0.084) - this node is a cross-community bridge._
- **Why does `Hike` connect `hike.dart` to `home_page.dart`, `hike_details_page.dart`, `search_page.dart`?**
  _High betweenness centrality (0.039) - this node is a cross-community bridge._
- **Why does `AuthRepository` connect `auth_page.dart` to `app.dart`?**
  _High betweenness centrality (0.032) - this node is a cross-community bridge._
- **What connects `ONESIGNAL_APP_ID`, `ONESIGNAL_REST_API_KEY`, `corsHeaders` to the rest of the system?**
  _254 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `home_page.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.11695906432748537 - nodes in this community are weakly interconnected._
- **Should `auth_page.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.05603864734299517 - nodes in this community are weakly interconnected._
- **Should `home_shell.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.1038961038961039 - nodes in this community are weakly interconnected._