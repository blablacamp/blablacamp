import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shapes.dart';
import '../data/auth_repository.dart';
import '../cubit/auth_cubit.dart';

/// Email/password sign-in & sign-up. [role] comes from onboarding and is used
/// only when creating a new account.
class AuthPage extends StatelessWidget {
  const AuthPage({super.key, this.role = 'campmate'});

  final String role;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => AuthCubit(ctx.read<AuthRepository>(), role: role),
      child: const _AuthView(),
    );
  }
}

class _AuthView extends StatefulWidget {
  const _AuthView();

  @override
  State<_AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<_AuthView> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().submit(
          email: _email.text,
          password: _password.text,
          displayName: _name.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: BlocConsumer<AuthCubit, AuthFormState>(
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);
          if (state.error != null) {
            messenger.showSnackBar(SnackBar(content: Text(state.error!)));
          } else if (state.info != null) {
            messenger.showSnackBar(SnackBar(content: Text(state.info!)));
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BlaBlaCamp',
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        )),
                    const SizedBox(height: 24),
                    Text(
                        state.isSignUp
                            ? 'Створи профіль мандрівника'
                            : 'З поверненням',
                        style: GoogleFonts.unbounded(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        )),
                    const SizedBox(height: 8),
                    Text(
                        state.isSignUp
                            ? 'Кілька секунд — і ти в спільноті.'
                            : 'Увійди, щоб побачити, хто куди йде.',
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        )),
                    const SizedBox(height: 28),
                    if (state.isSignUp) ...[
                      _Field(
                        controller: _name,
                        label: "Ім'я",
                        hint: 'Як тебе звати',
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? "Вкажи ім'я"
                            : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    _Field(
                      controller: _email,
                      label: 'Email',
                      hint: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'Введи коректний email'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _Field(
                      controller: _password,
                      label: 'Пароль',
                      hint: 'мінімум 6 символів',
                      obscure: true,
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Пароль від 6 символів'
                          : null,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: Material(
                        color: AppColors.accent,
                        borderRadius: AppShapes.leaf,
                        child: InkWell(
                          borderRadius: AppShapes.leaf,
                          onTap: state.submitting ? null : _submit,
                          child: Center(
                            child: state.submitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: AppColors.cream),
                                  )
                                : Text(
                                    state.isSignUp
                                        ? 'Зареєструватися'
                                        : 'Увійти',
                                    style: GoogleFonts.manrope(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.cream,
                                    )),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: context.read<AuthCubit>().toggleMode,
                        child: Text(
                          state.isSignUp
                              ? 'Вже маєш акаунт? Увійти'
                              : 'Немає акаунту? Створити',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF747A78),
            )),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accent, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
