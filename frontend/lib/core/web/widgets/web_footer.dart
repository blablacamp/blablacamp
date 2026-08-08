import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../responsive/responsive.dart';
import '../../theme/app_colors.dart';

/// Dark site footer for the web layout. Node: footer (105:1247).
class WebFooter extends StatelessWidget {
  const WebFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.ink,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: MaxWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 80,
              runSpacing: 32,
              children: [
                SizedBox(
                  width: 280,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/'),
                        child: Text('BlaBlaCamp',
                            style: GoogleFonts.manrope(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.cream,
                            )),
                      ),
                      const SizedBox(height: 12),
                      Text(
                          'Спільнота, що обʼєднує мандрівників для спільних походів Карпатами.',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            height: 1.5,
                            color: AppColors.mutedOnDark,
                          )),
                    ],
                  ),
                ),
                _FooterCol('Продукт', const [
                  ('Як це працює', '/'),
                  ('Пошук походів', '/search'),
                  ('Стати організатором', '/role'),
                ]),
                _FooterCol('Спільнота', const [
                  ('Правила', '/rules'),
                  ('Безпека', '/safety'),
                  ('Контакти', '/contact'),
                ]),
              ],
            ),
            const SizedBox(height: 40),
            Divider(color: AppColors.cream.withValues(alpha: 0.15)),
            const SizedBox(height: 16),
            Text('© 2026 BlaBlaCamp',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppColors.mutedOnDark,
                )),
          ],
        ),
      ),
    );
  }
}

class _FooterCol extends StatelessWidget {
  const _FooterCol(this.title, this.links);
  final String title;
  final List<(String, String)> links;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(),
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.accent,
            )),
        const SizedBox(height: 14),
        for (final (label, path) in links)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _FooterLink(label: label, path: path),
          ),
      ],
    );
  }
}

class _FooterLink extends StatefulWidget {
  const _FooterLink({required this.label, required this.path});
  final String label;
  final String path;

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => context.go(widget.path),
        child: Text(widget.label,
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: _hover ? AppColors.cream : AppColors.mutedOnDark,
              decoration:
                  _hover ? TextDecoration.underline : TextDecoration.none,
              decorationColor: AppColors.cream,
            )),
      ),
    );
  }
}
