import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/brand/app_logo.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shapes.dart';
import '../cubit/onboarding_cubit.dart';

/// First-run screen: brand, slogan and the campmate/campmaker role choice.
/// Node: terrain-onboarding (94:4).
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingCubit(),
      child: const _OnboardingView(),
    );
  }
}

class _OnboardingView extends StatelessWidget {
  const _OnboardingView();

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) return const _OnboardingWeb();

    final size = MediaQuery.sizeOf(context);
    final heroHeight = size.height * 0.55;

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        children: [
          // Hero photo with a fade into the dark background.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroHeight,
            child: ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.white, Colors.transparent],
                stops: [0, 0.6, 1],
              ).createShader(rect),
              blendMode: BlendMode.dstIn,
              child: Image.asset(
                'assets/images/onboarding_hero.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BlaBlaCamp',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.cream,
                    ),
                  ),
                  const Spacer(),
                  const _SloganBlock(),
                  const SizedBox(height: 24),
                  const _RoleSelector(),
                  const SizedBox(height: 16),
                  const _ContinueButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Web layout for the role picker: two columns, centered, constrained.
class _OnboardingWeb extends StatelessWidget {
  const _OnboardingWeb();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const AppLogo(size: 20, onDark: true),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.push('/auth'),
                        child: Text('Увійти',
                            style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.cream)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            _SloganBlock(),
                            SizedBox(height: 32),
                            _RoleSelector(),
                            SizedBox(height: 20),
                            _ContinueButton(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48),
                      Expanded(
                        flex: 6,
                        child: ClipRRect(
                          borderRadius: AppShapes.leaf,
                          child: AspectRatio(
                            aspectRatio: 4 / 3,
                            child: Image.asset(
                              'assets/images/onboarding_hero.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SloganBlock extends StatelessWidget {
  const _SloganBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Незнайомі на вокзалі.\nСвої — на зворотній дорозі.',
          style: GoogleFonts.unbounded(
            fontSize: 26,
            height: 34 / 26,
            fontWeight: FontWeight.w600,
            color: AppColors.cream,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Знайди похід і людей, з якими захочеться піти ще раз.',
          style: GoogleFonts.manrope(
            fontSize: 15,
            height: 22 / 15,
            color: AppColors.mutedOnDark,
          ),
        ),
      ],
    );
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector();

  @override
  Widget build(BuildContext context) {
    final selected = context.watch<OnboardingCubit>().state.selectedRole;
    return Column(
      children: [
        _RoleCard(
          icon: 'assets/icons/compass.svg',
          title: 'Хочу приєднатися',
          subtitle: 'Кемпмейт · знайду готовий похід',
          role: UserRole.campmate,
          selected: selected == UserRole.campmate,
        ),
        const SizedBox(height: 12),
        _RoleCard(
          icon: 'assets/icons/map_pin.svg',
          title: 'Хочу зібрати групу',
          subtitle: 'Кемпмейкер · створю власний маршрут',
          role: UserRole.campmaker,
          selected: selected == UserRole.campmaker,
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.role,
    required this.selected,
  });

  final String icon;
  final String title;
  final String subtitle;
  final UserRole role;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppShapes.leaf,
      child: InkWell(
        borderRadius: AppShapes.leaf,
        onTap: () => context.read<OnboardingCubit>().selectRole(role),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: AppShapes.leaf,
            border: Border.all(
              color: selected ? AppColors.accent : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                icon,
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  AppColors.textPrimary,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: AppColors.accent,
        borderRadius: AppShapes.leaf,
        child: InkWell(
          borderRadius: AppShapes.leaf,
          onTap: () {
            final role = context.read<OnboardingCubit>().state.selectedRole;
            context.push('/auth', extra: role.value);
          },
          child: Center(
            child: Text(
              'Подивитися, хто куди йде',
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.cream,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
