import 'package:flutter/material.dart';

import '../../responsive/responsive.dart';
import '../../theme/app_colors.dart';
import 'web_footer.dart';
import 'web_nav_bar.dart';

/// Web page frame: top nav + content (+ optional footer). Wrap any app screen's
/// desktop layout with this so navigation chrome is consistent.
class WebChrome extends StatelessWidget {
  const WebChrome({
    super.key,
    required this.child,
    this.scrollable = true,
    this.footer = false,
    this.constrain = true,
    this.maxContentWidth = Breakpoints.contentMax,
  });

  final Widget child;
  final bool scrollable;
  final bool footer;
  final bool constrain;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    final content = constrain
        ? MaxWidth(
            maxWidth: maxContentWidth,
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24), child: child))
        : child;

    if (!scrollable) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        body: Column(
          children: [const WebNavBar(), Expanded(child: content)],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const WebNavBar(),
            content,
            if (footer) const WebFooter(),
          ],
        ),
      ),
    );
  }
}
