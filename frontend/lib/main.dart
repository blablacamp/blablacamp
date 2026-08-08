import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'core/logging/app_logger.dart';
import 'core/notifications/notifications_service.dart';
import 'core/router/app_router.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/hikes/data/hikes_repository.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // Clean web URLs (/search instead of /#/search); Firebase SPA rewrite serves
  // index.html for all paths so refresh/deep-links work.
  if (kIsWeb) usePathUrlStrategy();

  // Firebase (Crashlytics). Guarded so the app still runs if config is missing.
  var crashlyticsReady = false;
  try {
    await Firebase.initializeApp();
    crashlyticsReady = true;
  } catch (e) {
    AppLog.I.warn('firebase', 'init skipped', {'error': e.toString()});
  }

  // Crash logging: uncaught errors go to Crashlytics (native) AND our
  // client_logs sink via AppLog.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (crashlyticsReady) {
      FirebaseCrashlytics.instance.recordFlutterError(details);
    }
    AppLog.I.error('flutter', details.exceptionAsString(),
        error: details.exception,
        stackTrace: details.stack,
        context: {'library': details.library ?? 'unknown'});
  };
  binding.platformDispatcher.onError = (error, stack) {
    if (crashlyticsReady) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
    AppLog.I.error('platform', 'uncaught error', error: error, stackTrace: stack);
    return true;
  };

  // Wire Supabase only when configured, so the UI can still run standalone.
  SupabaseClient? client;
  if (Env.hasSupabase) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      // Supabase's newer "publishable key" and the classic anon key are the
      // same public client credential; anonKey is still accepted.
      // ignore: deprecated_member_use
      anonKey: Env.supabaseAnonKey,
      // Persist the session locally and silently refresh the access token, so a
      // returning user is logged straight back in while the refresh token is
      // valid (no re-login until it actually expires).
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: true,
      ),
    );
    client = Supabase.instance.client;
  }

  AppLog.I.configure(client: client);
  AppLog.I.info('app', 'startup', {
    'hasSupabase': Env.hasSupabase,
    'hasOneSignal': Env.hasOneSignal,
  });

  final auth = AuthRepository(client: client);
  final hikes = HikesRepository(client: client);

  // Push / email / in-app via OneSignal (no-op until ONESIGNAL_APP_ID is set).
  final notifications = NotificationsService();
  await notifications.init();

  // Keep OneSignal's external id in sync with the Supabase session.
  Future<void> syncUser(User? user) async {
    AppLog.I.setUser(user?.id);
    if (user != null) {
      AppLog.I.info('auth', 'session active', {'userId': user.id});
      await notifications.linkUser(userId: user.id, email: user.email);
    } else {
      await notifications.unlinkUser();
    }
  }

  await syncUser(auth.currentUser);
  auth.onAuthStateChange.listen((state) => syncUser(state.session?.user));

  final router = createRouter(auth);

  // Deep-link: tapping a push with a hikeId opens that hike.
  notifications.addClickListener((event) {
    final hikeId = event.notification.additionalData?['hikeId'];
    if (hikeId is String && hikeId.isNotEmpty) {
      AppLog.I.info('push', 'clicked', {'hikeId': hikeId});
      router.push('/hike/$hikeId');
    }
  });

  runApp(BlablacampApp(
    router: router,
    authRepository: auth,
    hikesRepository: hikes,
    notifications: notifications,
  ));
}
