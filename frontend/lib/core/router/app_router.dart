import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/view/auth_page.dart';
import '../../features/hikes/data/models/hike.dart';
import '../../features/hikes/view/create_hike_page.dart';
import '../../features/hikes/view/hike_details_page.dart';
import '../../features/onboarding/view/onboarding_page.dart';
import '../../features/search/view/search_page.dart';
import '../../features/shell/home_shell.dart';

/// Builds the router. Auth gating is active only when Supabase is configured;
/// in UI-preview mode the app browses freely.
GoRouter createRouter(AuthRepository auth) {
  const publicRoutes = {'/onboarding', '/auth'};

  return GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: _GoRouterRefreshStream(auth.onAuthStateChange),
    redirect: (context, state) {
      if (!auth.isConfigured) return null; // preview mode — no gating
      final loggedIn = auth.currentSession != null;
      final atPublic = publicRoutes.contains(state.matchedLocation);
      if (!loggedIn && !atPublic) return '/onboarding';
      if (loggedIn && atPublic) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) =>
            AuthPage(role: state.extra as String? ?? 'campmate'),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => HomeShell(role: state.extra as String?),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => SearchPage(
          onOpenHike: (hike) => context.push('/hike', extra: hike),
        ),
      ),
      GoRoute(
        path: '/hike',
        builder: (context, state) => HikeDetailsPage(hike: state.extra as Hike),
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
    ],
  );
}

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
