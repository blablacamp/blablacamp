import 'package:flutter/widgets.dart';

/// Layout breakpoints. Below [desktop] we render the mobile layout.
abstract final class Breakpoints {
  static const double tablet = 640;
  static const double desktop = 900;
  static const double contentMax = 1200; // max content width on wide screens
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  bool get isDesktop => screenWidth >= Breakpoints.desktop;
  bool get isMobile => !isDesktop;
}

/// Picks a layout by width. Logic (cubits/repos) is shared; only the view
/// differs. Use one per feature:
///   ResponsiveLayout(mobile: (c) => HomeMobile(), desktop: (c) => HomeWeb())
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({super.key, required this.mobile, required this.desktop});

  final WidgetBuilder mobile;
  final WidgetBuilder desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= Breakpoints.desktop
          ? desktop(context)
          : mobile(context),
    );
  }
}

/// Centers content and caps its width on wide screens (marketing/app sections).
class MaxWidth extends StatelessWidget {
  const MaxWidth({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.contentMax,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}
