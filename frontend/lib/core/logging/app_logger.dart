import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum LogLevel { debug, info, warn, error }

/// App-wide logger. Prints to the console and, when Supabase is configured,
/// also streams structured rows into the `client_logs` table (fire-and-forget).
///
/// Usage:
///   AppLog.I.info('auth', 'sign-in tapped', {'email': email});
///   AppLog.I.error('hikes', 'load failed', error: e, stackTrace: s);
class AppLog {
  AppLog._();
  static final AppLog I = AppLog._();

  SupabaseClient? _client;
  String? _platform;
  String? _userId;

  void configure({SupabaseClient? client, String? platform}) {
    _client = client;
    _platform = platform;
  }

  void setUser(String? userId) => _userId = userId;

  void debug(String tag, String message, [Map<String, dynamic>? context]) =>
      _log(LogLevel.debug, tag, message, context);

  void info(String tag, String message, [Map<String, dynamic>? context]) =>
      _log(LogLevel.info, tag, message, context);

  void warn(String tag, String message, [Map<String, dynamic>? context]) =>
      _log(LogLevel.warn, tag, message, context);

  void error(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    final ctx = <String, dynamic>{...?context};
    if (error != null) {
      ctx['error'] = error.toString();
      // Surface Supabase auth/postgrest status codes explicitly — this is how
      // we caught the signup 401.
      if (error is AuthException) ctx['statusCode'] = error.statusCode;
      if (error is PostgrestException) {
        ctx['code'] = error.code;
        ctx['details'] = error.details?.toString();
      }
    }
    _log(LogLevel.error, tag, message, ctx, error, stackTrace);
  }

  void _log(
    LogLevel level,
    String tag,
    String message,
    Map<String, dynamic>? context, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    // Console
    developer.log(
      message,
      name: 'blablacamp/$tag',
      level: switch (level) {
        LogLevel.debug => 500,
        LogLevel.info => 800,
        LogLevel.warn => 900,
        LogLevel.error => 1000,
      },
      error: error,
      stackTrace: stackTrace,
    );

    // Remote sink (best-effort, never throws, never blocks).
    final client = _client;
    if (client == null) return;
    unawaited(_insert(client, level, tag, message, context));
  }

  Future<void> _insert(
    SupabaseClient client,
    LogLevel level,
    String tag,
    String message,
    Map<String, dynamic>? context,
  ) async {
    try {
      await client.from('client_logs').insert({
        'user_id': _userId,
        'level': level.name,
        'tag': tag,
        'message': message,
        'context': context ?? const {},
        'platform': _platform ?? defaultTargetPlatform.name,
      });
    } catch (_) {
      // Swallow — logging must never break the app or loop on itself.
    }
  }
}
