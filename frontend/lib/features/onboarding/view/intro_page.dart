import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shapes.dart';

/// First-run intro carousel (4 slides) before role selection.
/// Nodes: onboarding-splash/find-trip/create-group/get-ready (103:519…).
class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _Slide {
  const _Slide(this.image, this.title, this.body);
  final String image;
  final String title;
  final String body;
}

class _IntroPageState extends State<IntroPage> {
  final _controller = PageController();
  int _index = 0;

  static const _slides = [
    _Slide(
      'assets/images/onboarding_hero.jpg',
      'Незнайомі на вокзалі. Свої — на зворотній дорозі.',
      'BlaBlaCamp обʼєднує людей у горах Карпат. Знаходь напарників та створюй незабутні маршрути разом.',
    ),
    _Slide(
      'assets/images/home_hero.jpg',
      'Знайди свій похід',
      'Обери напрямок і дати — і приєднайся до груп, що вже збираються.',
    ),
    _Slide(
      'assets/images/backpack_hero.jpg',
      'Збери власну групу',
      'Створи маршрут, признач дати й запроси однодумців. Ти — організатор.',
    ),
    _Slide(
      'assets/images/cover_fallback.jpg',
      'Спорядись і рушай',
      'Чеклист спорядження, чат групи й нагадування — усе для впевненого старту.',
    ),
  ];

  bool get _isLast => _index == _slides.length - 1;

  void _next() {
    if (_isLast) {
      context.go('/role');
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => _SlideView(slide: _slides[i]),
          ),
          // Skip
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            right: 12,
            child: TextButton(
              onPressed: () => context.go('/role'),
              child: Text('Пропустити',
                  style: GoogleFonts.manrope(
                    color: AppColors.cream,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ),
          // Bottom: dots + CTA
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.paddingOf(context).bottom + 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _slides.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 6,
                        width: i == _index ? 22 : 6,
                        decoration: BoxDecoration(
                          color: i == _index
                              ? AppColors.accent
                              : AppColors.cream.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: Material(
                    color: AppColors.accent,
                    borderRadius: AppShapes.leaf,
                    child: InkWell(
                      borderRadius: AppShapes.leaf,
                      onTap: _next,
                      child: Center(
                        child: Text(_isLast ? 'Почати' : 'Далі',
                            style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.cream,
                            )),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(slide.image, fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x33121719), Color(0x40121719), Color(0xF2121719)],
              stops: [0, 0.45, 1],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
              24, 0, 24, MediaQuery.paddingOf(context).bottom + 150),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(slide.title,
                  style: GoogleFonts.unbounded(
                    fontSize: 26,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cream,
                  )),
              const SizedBox(height: 14),
              Text(slide.body,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    height: 1.5,
                    color: AppColors.mutedOnDark,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}
