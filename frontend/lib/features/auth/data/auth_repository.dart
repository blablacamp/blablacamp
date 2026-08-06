import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps Supabase Auth. When no client is configured (UI preview) it reports
/// itself as not-configured so the router skips auth gating entirely.
class AuthRepository {
  AuthRepository({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  bool get isConfigured => _client != null;
  Session? get currentSession => _client?.auth.currentSession;
  User? get currentUser => _client?.auth.currentUser;

  /// Emits on sign-in / sign-out / token refresh. Empty stream when unconfigured.
  Stream<AuthState> get onAuthStateChange =>
      _client?.auth.onAuthStateChange ?? const Stream<AuthState>.empty();

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await _require().auth.signInWithPassword(email: email, password: password);
  }

  /// display_name / default_role land in raw_user_meta_data and are read by the
  /// handle_new_user trigger to seed the profile row.
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    required String role,
  }) async {
    await _require().auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName, 'default_role': role},
    );
  }

  Future<void> signOut() async => _client?.auth.signOut();

  /// Loads the current user's profile row (display_name, bio, avatar_url, …).
  Future<Map<String, dynamic>?> fetchMyProfile() async {
    final client = _client;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) return null;
    return client.from('profiles').select().eq('id', uid).maybeSingle();
  }

  /// Updates the current user's profile.
  Future<void> updateMyProfile({
    required String displayName,
    String? bio,
  }) async {
    final client = _client;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) {
      throw StateError('Треба увійти.');
    }
    await client.from('profiles').update({
      'display_name': displayName,
      'bio': bio,
    }).eq('id', uid);
  }

  SupabaseClient _require() {
    final client = _client;
    if (client == null) {
      throw StateError('Автентифікація недоступна: Supabase не налаштовано.');
    }
    return client;
  }
}
