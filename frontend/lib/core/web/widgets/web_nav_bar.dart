import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../features/auth/data/auth_repository.dart';
import '../../responsive/responsive.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shapes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Top navigation bar for the web layout. Session-aware: shows app sections
/// when signed in, marketing CTAs otherwise.
class WebNavBar extends StatelessWidget {
  const WebNavBar({super.key, this.onDark = false});

  /// When placed over a dark hero, use light text.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final fg = onDark ? AppColors.cream : AppColors.textPrimary;
    final auth = context.read<AuthRepository>();
    final loggedIn = auth.currentSession != null;

    final links = <(String, String)>[
      ('Пошук', '/search'),
      if (loggedIn) ...[
        ('Обране', '/favorites'),
        ('Мої походи', '/my-hikes'),
        ('Повідомлення', '/messages'),
      ],
    ];

    return Container(
      color: onDark ? Colors.transparent : AppColors.cream,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: MaxWidth(
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.go(loggedIn ? '/home' : '/onboarding'),
              child: Text('BlaBlaCamp',
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: fg,
                  )),
            ),
            const SizedBox(width: 40),
            for (final (label, path) in links) ...[
              _NavLink(label, fg, () => context.go(path)),
              const SizedBox(width: 20),
            ],
            const Spacer(),
            if (loggedIn) ...[
              _PrimaryButton(
                  label: 'Створити похід',
                  onTap: () => context.push('/create-hike')),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => context.go('/profile'),
                child: const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.surface,
                  child: Icon(Icons.person, size: 20, color: AppColors.textSecondary),
                ),
              ),
            ] else ...[
              _NavLink('Увійти', fg, () => context.go('/auth')),
              const SizedBox(width: 12),
              _PrimaryButton(
                  label: 'Створити похід', onTap: () => context.go('/role')),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink(this.label, this.color, this.onTap);
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(label,
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: color,
          )),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accent,
      borderRadius: AppShapes.leafOf(14, 6),
      child: InkWell(
        borderRadius: AppShapes.leafOf(14, 6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Text(label,
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.cream,
              )),
        ),
      ),
    );
  }
}
