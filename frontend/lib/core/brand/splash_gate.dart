import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_logo.dart';

/// Plays a one-shot branded intro over [child] on cold start, then fades away.
/// The animation: the mountain mark springs in and draws, the wordmark rises
/// and fades in, then the whole veil dissolves to reveal the app.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.child});

  final Widget child;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _done = false;

  late final Animation<double> _markScale;
  late final Animation<double> _markFade;
  late final Animation<double> _wordFade;
  late final Animation<double> _wordSlide;
  late final Animation<double> _veilFade;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _markScale = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.0, 0.45, curve: Curves.elasticOut),
    );
    _markFade = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
    );
    _wordFade = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.35, 0.6, curve: Curves.easeOut),
    );
    _wordSlide = Tween<double>(begin: 12, end: 0).animate(CurvedAnimation(
      parent: _c,
      curve: const Interval(0.35, 0.65, curve: Curves.easeOutCubic),
    ));
    _veilFade = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.82, 1.0, curve: Curves.easeInOut),
    );

    _c.forward().whenComplete(() {
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!_done)
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              return IgnorePointer(
                child: Opacity(
                  opacity: 1 - _veilFade.value,
                  child: Container(
                    color: AppColors.ink,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Opacity(
                          opacity: _markFade.value,
                          child: Transform.scale(
                            scale: 0.6 + 0.4 * _markScale.value,
                            child: const AppLogoMark(
                                size: 96, color: AppColors.accent),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Opacity(
                          opacity: _wordFade.value,
                          child: Transform.translate(
                            offset: Offset(0, _wordSlide.value),
                            child: const AppWordmark(
                                size: 30,
                                showSubtitle: false,
                                onDark: true,
                                center: true),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
