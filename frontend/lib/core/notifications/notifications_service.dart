import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../config/env.dart';

/// Thin wrapper around the OneSignal SDK covering all three channels we use:
/// push notifications, email, and in-app messages.
///
/// Follows OneSignal's Flutter guidance: initialize before runApp, do NOT
/// request push permission at launch (defer to an explicit prompt/dialog).
/// Server-side sends go through the Supabase `notify` edge function, which
/// targets users by external id = the Supabase user id set in [linkUser].
class NotificationsService {
  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Call once at startup. Safe to call when OneSignal isn't configured.
  /// No-op on web — onesignal_flutter is native-only; web push uses the
  /// separate OneSignal Web (JS) SDK wired in web/index.html.
  Future<void> init() async {
    if (kIsWeb || !Env.hasOneSignal || _initialized) return;
    OneSignal.Debug.setLogLevel(
        kDebugMode ? OSLogLevel.warn : OSLogLevel.none);
    OneSignal.initialize(Env.oneSignalAppId);
    _initialized = true;
  }

  /// Whether push permission is already granted.
  bool get permissionGranted =>
      _initialized && OneSignal.Notifications.permission;

  /// Explicitly ask for push permission (call from a user-initiated dialog).
  Future<bool> requestPermission() async {
    if (!_initialized) return false;
    return OneSignal.Notifications.requestPermission(true);
  }

  /// Associate the OneSignal subscription with a signed-in user so the server
  /// can target them, and register their email for the email channel.
  Future<void> linkUser({required String userId, String? email}) async {
    if (!_initialized) return;
    await OneSignal.login(userId);
    if (email != null && email.isNotEmpty) {
      OneSignal.User.addEmail(email);
    }
  }

  /// Drop the association on sign-out.
  Future<void> unlinkUser() async {
    if (!_initialized) return;
    await OneSignal.logout();
  }

  /// In-app message triggers show contextual IAMs configured in the dashboard.
  void setTrigger(String key, String value) {
    if (!_initialized) return;
    OneSignal.InAppMessages.addTrigger(key, value);
  }

  void setTag(String key, String value) {
    if (!_initialized) return;
    OneSignal.User.addTagWithKey(key, value);
  }

  void addClickListener(void Function(OSNotificationClickEvent) handler) {
    if (!_initialized) return;
    OneSignal.Notifications.addClickListener(handler);
  }

  void addForegroundListener(
      void Function(OSNotificationWillDisplayEvent) handler) {
    if (!_initialized) return;
    OneSignal.Notifications.addForegroundWillDisplayListener(handler);
  }

  bool _isRegistered(String? id) =>
      id != null && id.isNotEmpty && !id.startsWith('local-');

  /// Invokes [onRegistered] exactly once when the device gets a real push
  /// subscription id (used to confirm the integration / prompt for permission).
  void onceRegistered(void Function() onRegistered) {
    if (!_initialized) return;
    var fired = false;
    void fire() {
      if (fired) return;
      fired = true;
      onRegistered();
    }

    OneSignal.User.pushSubscription.addObserver((state) {
      if (_isRegistered(state.current.id)) fire();
    });
    if (_isRegistered(OneSignal.User.pushSubscription.id)) fire();
  }
}
