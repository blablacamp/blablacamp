import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logging/app_logger.dart';
import '../data/auth_repository.dart';

enum AuthMode { signIn, signUp }

class AuthFormState extends Equatable {
  const AuthFormState({
    this.mode = AuthMode.signIn,
    this.submitting = false,
    this.error,
    this.info,
  });

  final AuthMode mode;
  final bool submitting;
  final String? error;
  final String? info;

  bool get isSignUp => mode == AuthMode.signUp;

  AuthFormState copyWith({
    AuthMode? mode,
    bool? submitting,
    String? error,
    String? info,
  }) =>
      AuthFormState(
        mode: mode ?? this.mode,
        submitting: submitting ?? this.submitting,
        error: error,
        info: info,
      );

  @override
  List<Object?> get props => [mode, submitting, error, info];
}

/// Drives the sign-in / sign-up form. On success the router's auth redirect
/// takes over navigation (via the auth-state stream).
class AuthCubit extends Cubit<AuthFormState> {
  AuthCubit(this._repo, {required this.role}) : super(const AuthFormState());

  final AuthRepository _repo;

  /// Chosen on onboarding; applied only when signing up.
  final String role;

  void toggleMode() {
    emit(AuthFormState(
      mode: state.isSignUp ? AuthMode.signIn : AuthMode.signUp,
    ));
  }

  Future<void> submit({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final mode = state.isSignUp ? 'signUp' : 'signIn';
    AppLog.I.info('auth', '$mode submit', {'email': email.trim(), 'role': role});
    emit(state.copyWith(submitting: true, error: null, info: null));
    try {
      if (state.isSignUp) {
        await _repo.signUp(
          email: email.trim(),
          password: password,
          displayName: displayName.trim(),
          role: role,
        );
        // If email confirmation is on, there is no session yet.
        if (_repo.currentSession == null) {
          emit(state.copyWith(
            submitting: false,
            info: 'Перевір пошту — треба підтвердити email, щоб увійти.',
          ));
          return;
        }
      } else {
        await _repo.signInWithPassword(email: email.trim(), password: password);
      }
      AppLog.I.info('auth', '$mode success',
          {'hasSession': _repo.currentSession != null});
      emit(state.copyWith(submitting: false));
    } catch (e, s) {
      AppLog.I.error('auth', '$mode failed', error: e, stackTrace: s,
          context: {'mode': mode});
      emit(state.copyWith(submitting: false, error: _message(e)));
    }
  }

  String _message(Object e) {
    final s = e.toString();
    if (s.contains('Invalid login credentials')) return 'Невірний email або пароль.';
    if (s.contains('already registered')) return 'Такий email уже зареєстровано.';
    return s.replaceFirst('Exception: ', '');
  }
}
