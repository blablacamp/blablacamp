/// Runtime configuration, provided at build time via --dart-define.
///
/// Example:
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJhbGci... \
///     --dart-define=ONESIGNAL_APP_ID=00000000-0000-0000-0000-000000000000
///
/// Only public client credentials belong here — never the Supabase
/// service_role key or the OneSignal REST API key (those live server-side).
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const oneSignalAppId = String.fromEnvironment('ONESIGNAL_APP_ID');

  /// True when both values are present, so the app can boot without a backend
  /// (e.g. to preview UI) and only wire Supabase when configured.
  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get hasOneSignal => oneSignalAppId.isNotEmpty;
}
