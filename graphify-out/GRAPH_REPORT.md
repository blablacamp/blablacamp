# Graph Report - blablacamp  (2026-08-05)

## Corpus Check
- 60 files · ~328,150 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 665 nodes · 931 edges · 53 communities (40 shown, 13 thin omitted)
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
- auth_repository.dart
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
- chat_page.dart
- search_cubit.dart
- onboarding_cubit.dart
- chat_cubit.dart
- favorites_cubit.dart
- @example
- main.dart
- app.dart
- conversations_cubit.dart
- notifications_service.dart
- public.hikes

## God Nodes (most connected - your core abstractions)
1. `HikesRepository` - 27 edges
2. `AuthRepository` - 9 edges
3. `OnboardingCubit` - 8 edges
4. `public.profiles` - 7 edges
5. `public.hikes` - 7 edges
6. `AuthCubit` - 7 edges
7. `BackpackCubit` - 6 edges
8. `FavoritesCubit` - 6 edges
9. `Hike` - 6 edges
10. `HomeCubit` - 6 edges

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

## Communities (53 total, 13 thin omitted)

### Community 0 - "home_page.dart"
Cohesion: 0.12
Nodes (17): ../../../core/widgets/avatar_circle.dart, ../cubit/home_cubit.dart, HomeCubit, HomeState, build, _ConsoleDivider, _ConsoleField, _GatheringCard (+9 more)

### Community 1 - "auth_page.dart"
Cohesion: 0.06
Nodes (41): ../../auth/data/auth_repository.dart, ../../core/theme/app_colors.dart, ../cubit/auth_cubit.dart, ../data/auth_repository.dart, FormState, AuthCubit, AuthFormState, AuthMode (+33 more)

### Community 2 - "home_shell.dart"
Cohesion: 0.09
Nodes (25): ../backpack/view/backpack_page.dart, ../favorites/view/favorites_page.dart, _AuthView, _AuthViewState, HikeDetailsPage, _HikeDetailsPageState, _ChatView, _ChatViewState (+17 more)

### Community 3 - "app_colors.dart"
Cohesion: 0.06
Nodes (31): BorderRadius?, double?, Env, hasOneSignal, hasSupabase, oneSignalAppId, supabaseAnonKey, supabaseUrl (+23 more)

### Community 4 - "home_cubit.dart"
Cohesion: 0.11
Nodes (16): dayNum, description, fromMap, HikeDay, title, copyWith, error, gathering (+8 more)

### Community 5 - "AppDelegate"
Cohesion: 0.11
Nodes (14): Any, Bool, Flutter, FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, FlutterSceneDelegate, AppDelegate (+6 more)

### Community 6 - "hike.dart"
Cohesion: 0.04
Nodes (46): DateTime, easy,
  moderate,
  hard,, coverUrl, currency, _date, description, difficulty, distanceKm (+38 more)

### Community 7 - "app_shapes.dart"
Cohesion: 0.22
Nodes (8): AppShapes, _large, leaf, leafOf, _small, package:flutter/widgets.dart, static const BorderRadius, static const double

### Community 8 - "Blablacamp"
Cohesion: 0.20
Nodes (9): Backend (Supabase), Blablacamp, Domain in one paragraph, Frontend (Flutter), Link the cloud project (one-time), Notifications (OneSignal), Or run fully local (needs Docker running), Push schema + seed (+1 more)

### Community 9 - "hikes_repository.dart"
Cohesion: 0.06
Nodes (34): _andrii, _client, currentUserId, favoriteHikeIds, fetchById, fetchChecklist, fetchFavoriteHikes, fetchGathering (+26 more)

### Community 10 - "auth_repository.dart"
Cohesion: 0.13
Nodes (14): bool get, _client, currentSession, currentUser, isConfigured, onAuthStateChange, _require, signInWithPassword (+6 more)

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
Nodes (16): ../../../core/utils/date_format.dart, ../../../core/widgets/hike_cover.dart, ../cubit/search_cubit.dart, active, _FeaturedCard, _FilterRow, _FilterTab, _GuidedCard (+8 more)

### Community 31 - "app_router.dart"
Cohesion: 0.14
Nodes (13): ChangeNotifier, dart:async, ../../features/auth/view/auth_page.dart, ../../features/hikes/data/models/hike.dart, ../../features/hikes/view/hike_details_page.dart, ../../features/onboarding/view/onboarding_page.dart, ../../features/search/view/search_page.dart, ../../features/shell/home_shell.dart (+5 more)

### Community 32 - "index.ts"
Cohesion: 0.33
Nodes (4): corsHeaders, NotifyBody, ONESIGNAL_APP_ID, ONESIGNAL_REST_API_KEY

### Community 33 - "date_format.dart"
Cohesion: 0.33
Nodes (5): _day, e, formatDateRange, _monthsGenitive, s

### Community 34 - "backpack_page.dart"
Cohesion: 0.05
Nodes (44): Color, ../cubit/backpack_cubit.dart, BackpackCubit, BackpackState, BackpackStatus, copyWith, error, hikeId (+36 more)

### Community 35 - "onboarding_page.dart"
Cohesion: 0.14
Nodes (17): ../../../core/theme/app_shapes.dart, ../cubit/onboarding_cubit.dart, OnboardingCubit, build, _ContinueButton, icon, OnboardingPage, _OnboardingView (+9 more)

### Community 36 - "checklist_item.dart"
Cohesion: 0.12
Nodes (16): actionLabel, actionNote, category, ChecklistItem, ChecklistStatus, copyWith, fromMap, fromValue (+8 more)

### Community 37 - "hike_details_page.dart"
Cohesion: 0.08
Nodes (24): ../data/hikes_repository.dart, ../data/models/hike.dart, ../data/models/hike_day.dart, build, child, color, createState, day (+16 more)

### Community 38 - "StatelessWidget"
Cohesion: 0.15
Nodes (13): _ItemRow, _CheckRow, _CircleButton, _DayRow, _Hero, _NoFeeBox, _OrganizerCard, _Panel (+5 more)

### Community 39 - "HikesRepository"
Cohesion: 0.12
Nodes (21): chat_page.dart, ../../../core/widgets/hike_list_tile.dart, ../cubit/conversations_cubit.dart, ../cubit/favorites_cubit.dart, createRouter, BackpackPage, FavoritesCubit, build (+13 more)

### Community 41 - "chat_page.dart"
Cohesion: 0.05
Nodes (38): app_colors.dart, ../cubit/chat_cubit.dart, ../../features/hikes/data/models/profile_ref.dart, AppTheme, light, AvatarCircle, build, _initials (+30 more)

### Community 42 - "search_cubit.dart"
Cohesion: 0.12
Nodes (16): all, copyWith, error, filter, load, props, _repo, SearchCubit (+8 more)

### Community 43 - "onboarding_cubit.dart"
Cohesion: 0.22
Nodes (8): copyWith, props, selectedRole, selectRole, UserRole, value, List, package:equatable/equatable.dart

### Community 44 - "chat_cubit.dart"
Cohesion: 0.13
Nodes (15): Cubit, ChatCubit, ChatState, ChatStatus, copyWith, hikeId, load, messages (+7 more)

### Community 45 - "favorites_cubit.dart"
Cohesion: 0.17
Nodes (11): Equatable, copyWith, FavoritesState, FavoritesStatus, hikes, load, props, remove (+3 more)

### Community 47 - "main.dart"
Cohesion: 0.15
Nodes (12): app.dart, core/config/env.dart, core/router/app_router.dart, features/hikes/data/hikes_repository.dart, auth, client, hikes, init (+4 more)

### Community 48 - "app.dart"
Cohesion: 0.17
Nodes (11): core/notifications/notifications_service.dart, core/theme/app_theme.dart, features/auth/data/auth_repository.dart, authRepository, BlablacampApp, build, hikesRepository, notifications (+3 more)

### Community 49 - "conversations_cubit.dart"
Cohesion: 0.18
Nodes (11): ConversationsCubit, ConversationsState, ConversationsStatus, copyWith, hikes, load, props, _repo (+3 more)

### Community 50 - "notifications_service.dart"
Cohesion: 0.20
Nodes (9): ../config/env.dart, init, _initialized, linkUser, NotificationsService, setTrigger, unlinkUser, package:flutter/foundation.dart (+1 more)

## Knowledge Gaps
- **332 isolated node(s):** `ONESIGNAL_APP_ID`, `ONESIGNAL_REST_API_KEY`, `corsHeaders`, `NotifyBody`, `XCTest` (+327 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **13 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `HikesRepository` connect `HikesRepository` to `home_page.dart`, `backpack_page.dart`, `home_shell.dart`, `home_cubit.dart`, `hike_details_page.dart`, `hikes_repository.dart`, `chat_page.dart`, `search_cubit.dart`, `chat_cubit.dart`, `favorites_cubit.dart`, `app.dart`, `conversations_cubit.dart`, `search_page.dart`?**
  _High betweenness centrality (0.123) - this node is a cross-community bridge._
- **Why does `AuthRepository` connect `auth_page.dart` to `app.dart`, `auth_repository.dart`?**
  _High betweenness centrality (0.024) - this node is a cross-community bridge._
- **Why does `Hike` connect `app_colors.dart` to `home_page.dart`, `hike_details_page.dart`, `hike.dart`, `chat_page.dart`, `search_page.dart`?**
  _High betweenness centrality (0.024) - this node is a cross-community bridge._
- **What connects `ONESIGNAL_APP_ID`, `ONESIGNAL_REST_API_KEY`, `corsHeaders` to the rest of the system?**
  _332 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `home_page.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.12418300653594772 - nodes in this community are weakly interconnected._
- **Should `auth_page.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.056025369978858354 - nodes in this community are weakly interconnected._
- **Should `home_shell.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.08923076923076922 - nodes in this community are weakly interconnected._