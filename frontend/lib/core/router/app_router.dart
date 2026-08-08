import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/view/auth_page.dart';
import '../../features/backpack/view/backpack_page.dart';
import '../../features/favorites/view/favorites_page.dart';
import '../../features/hikes/data/models/hike.dart';
import '../../features/hikes/view/create_hike_page.dart';
import '../../features/hikes/view/hike_details_page.dart';
import '../../features/hikes/view/hike_details_web.dart';
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
  const entryRoutes = {'/onboarding', '/role', '/auth'};
  const authOnly = {'/home', '/create-hike', '/favorites', '/my-hikes', '/messages', '/profile'};
  bool needsAuth(String loc) => authOnly.any(loc.startsWith);

  return GoRouter(
    initialLocation: '/onboarding',
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
        path: '/onboarding',
        builder: (context, state) => const ResponsiveLayout(
          mobile: _introBuilder,
          desktop: _landingBuilder,
        ),
      ),
      GoRoute(
        path: '/role',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) =>
            AuthPage(role: state.extra as String? ?? 'campmate'),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => ResponsiveLayout(
          mobile: (c) => HomeShell(role: state.extra as String?),
          desktop: (c) => const SearchWebPage(),
        ),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => ResponsiveLayout(
          mobile: (c) => SearchPage(
            onOpenHike: (hike) => c.push('/hike', extra: hike),
          ),
          desktop: (c) => const SearchWebPage(),
        ),
      ),
      GoRoute(
        path: '/hike',
        builder: (context, state) {
          final hike = state.extra as Hike;
          return ResponsiveLayout(
            mobile: (c) => HikeDetailsPage(hike: hike),
            desktop: (c) => HikeDetailsWebPage(hike: hike),
          );
        },
      ),
      GoRoute(
        path: '/hike/:id',
        builder: (context, state) =>
            HikeDetailsLoader(hikeId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/create-hike',
        builder: (context, state) => const CreateHikePage(),
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => ResponsiveLayout(
          mobile: (c) => const FavoritesPage(),
          desktop: (c) => const WebChrome(scrollable: false, child: FavoritesPage()),
        ),
      ),
      GoRoute(
        path: '/my-hikes',
        builder: (context, state) => ResponsiveLayout(
          mobile: (c) => const BackpackPage(),
          desktop: (c) => const WebChrome(scrollable: false, child: BackpackPage()),
        ),
      ),
      GoRoute(
        path: '/messages',
        builder: (context, state) => ResponsiveLayout(
          mobile: (c) => const MessagesPage(),
          desktop: (c) => const WebChrome(scrollable: false, child: MessagesPage()),
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => ResponsiveLayout(
          mobile: (c) => const ProfilePage(),
          desktop: (c) => const WebChrome(scrollable: false, child: ProfilePage()),
        ),
      ),
    ],
  );
}

Widget _introBuilder(BuildContext context) => const IntroPage();
Widget _landingBuilder(BuildContext context) => const LandingPage();

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
