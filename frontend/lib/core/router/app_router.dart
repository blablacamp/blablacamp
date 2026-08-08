import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/view/auth_page.dart';
import '../../features/backpack/view/backpack_page.dart';
import '../../features/favorites/view/favorites_page.dart';
import '../../features/hikes/data/models/hike.dart';
import '../../features/hikes/view/create_hike_page.dart';
import '../../features/hikes/view/hike_details_page.dart';
import '../../features/hikes/view/hike_details_web.dart';
import '../../features/info/view/info_page.dart';
import '../../features/landing/view/landing_page.dart';
import '../../features/messages/view/messages_page.dart';
import '../../features/onboarding/view/intro_page.dart';
import '../../features/onboarding/view/onboarding_page.dart';
import '../../features/profile/view/profile_page.dart';
import '../../features/search/view/search_page.dart';
import '../../features/search/view/search_web.dart';
import '../../features/shell/home_shell.dart';
import '../responsive/responsive.dart';
import '../web/widgets/web_chrome.dart';

/// Builds the router. Auth gating is active only when Supabase is configured;
/// in UI-preview mode the app browses freely.
GoRouter createRouter(AuthRepository auth) {
  // Entry/auth screens; browsing (/search, /hike) is public so web visitors can
  // explore before signing in. Only the app shell + actions require a session.
  const entryRoutes = {'/', '/onboarding', '/role', '/auth'};
  const authOnly = {'/home', '/create-hike', '/favorites', '/my-hikes', '/messages', '/profile'};
  bool needsAuth(String loc) => authOnly.any(loc.startsWith);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: _GoRouterRefreshStream(auth.onAuthStateChange),
    redirect: (context, state) {
      if (!auth.isConfigured) return null; // preview mode — no gating
      final loggedIn = auth.currentSession != null;
      final loc = state.matchedLocation;
      if (!loggedIn && needsAuth(loc)) return '/auth';
      if (loggedIn && entryRoutes.contains(loc)) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _page(state, const ResponsiveLayout(
          mobile: _introBuilder,
          desktop: _landingBuilder,
        )),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => _page(state, const ResponsiveLayout(
          mobile: _introBuilder,
          desktop: _landingBuilder,
        )),
      ),
      GoRoute(
        path: '/rules',
        pageBuilder: (context, state) =>
            _page(state, const InfoPage(topic: 'rules')),
      ),
      GoRoute(
        path: '/safety',
        pageBuilder: (context, state) =>
            _page(state, const InfoPage(topic: 'safety')),
      ),
      GoRoute(
        path: '/contact',
        pageBuilder: (context, state) =>
            _page(state, const InfoPage(topic: 'contact')),
      ),
      GoRoute(
        path: '/role',
        pageBuilder: (context, state) => _page(state, const OnboardingPage()),
      ),
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) =>
            _page(state, AuthPage(role: state.extra as String? ?? 'campmate')),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => _page(
            state,
            ResponsiveLayout(
              mobile: (c) => HomeShell(role: state.extra as String?),
              desktop: (c) => const SearchWebPage(),
            )),
      ),
      GoRoute(
        path: '/search',
        pageBuilder: (context, state) => _page(
            state,
            ResponsiveLayout(
              mobile: (c) => SearchPage(
                onOpenHike: (hike) => c.push('/hike', extra: hike),
              ),
              desktop: (c) => const SearchWebPage(),
            )),
      ),
      GoRoute(
        path: '/hike',
        pageBuilder: (context, state) {
          final hike = state.extra as Hike;
          return _page(
              state,
              ResponsiveLayout(
                mobile: (c) => HikeDetailsPage(hike: hike),
                desktop: (c) => HikeDetailsWebPage(hike: hike),
              ));
        },
      ),
      GoRoute(
        path: '/hike/:id',
        pageBuilder: (context, state) =>
            _page(state, HikeDetailsLoader(hikeId: state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/create-hike',
        pageBuilder: (context, state) => _page(
            state,
            const ResponsiveLayout(
              mobile: _createHikeBuilder,
              desktop: _createHikeWebBuilder,
            )),
      ),
      GoRoute(
        path: '/favorites',
        pageBuilder: (context, state) => _page(
            state,
            const ResponsiveLayout(
              mobile: _favoritesBuilder,
              desktop: _favoritesWebBuilder,
            )),
      ),
      GoRoute(
        path: '/my-hikes',
        pageBuilder: (context, state) => _page(
            state,
            const ResponsiveLayout(
              mobile: _backpackBuilder,
              desktop: _backpackWebBuilder,
            )),
      ),
      GoRoute(
        path: '/messages',
        pageBuilder: (context, state) => _page(
            state,
            const ResponsiveLayout(
              mobile: _messagesBuilder,
              desktop: _messagesWebBuilder,
            )),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) => _page(
            state,
            const ResponsiveLayout(
              mobile: _profileBuilder,
              desktop: _profileWebBuilder,
            )),
      ),
    ],
  );
}

/// Web navigation should feel like a website (instant), not a mobile push.
Page<void> _page(GoRouterState state, Widget child) => kIsWeb
    ? NoTransitionPage<void>(key: state.pageKey, child: child)
    : MaterialPage<void>(key: state.pageKey, child: child);

Widget _introBuilder(BuildContext context) => const IntroPage();
Widget _landingBuilder(BuildContext context) => const LandingPage();
Widget _createHikeBuilder(BuildContext context) => const CreateHikePage();
Widget _createHikeWebBuilder(BuildContext context) => const WebChrome(
    scrollable: false, maxContentWidth: 720, child: CreateHikePage());
Widget _favoritesBuilder(BuildContext context) => const FavoritesPage();
Widget _favoritesWebBuilder(BuildContext context) => const WebChrome(
    scrollable: false, maxContentWidth: 760, child: FavoritesPage());
Widget _backpackBuilder(BuildContext context) => const BackpackPage();
Widget _backpackWebBuilder(BuildContext context) => const WebChrome(
    scrollable: false, maxContentWidth: 760, child: BackpackPage());
Widget _messagesBuilder(BuildContext context) => const MessagesPage();
Widget _messagesWebBuilder(BuildContext context) => const WebChrome(
    scrollable: false, maxContentWidth: 760, child: MessagesPage());
Widget _profileBuilder(BuildContext context) => const ProfilePage();
Widget _profileWebBuilder(BuildContext context) => const WebChrome(
    scrollable: false, maxContentWidth: 760, child: ProfilePage());

/// Bridges a [Stream] to [Listenable] so GoRouter re-evaluates redirects when
/// the auth state changes.
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
