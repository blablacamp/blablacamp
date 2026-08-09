import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_shapes.dart';

/// "Легенда цих гір" — a warm lore panel (a Galician/Carpathian touch).
class LegendPanel extends StatelessWidget {
  const LegendPanel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFEFE7D6), // warm parchment
        borderRadius: AppShapes.leaf,
        border: Border.all(color: const Color(0xFFDCceb2)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_stories_outlined,
                  size: 18, color: Color(0xFF8A6B2E)),
              const SizedBox(width: 8),
              Text('ЛЕГЕНДА ЦИХ ГІР',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: const Color(0xFF8A6B2E),
                  )),
            ],
          ),
          const SizedBox(height: 10),
          Text(text,
              style: GoogleFonts.manrope(
                fontSize: 15,
                height: 1.55,
                fontStyle: FontStyle.italic,
                color: const Color(0xFF3B3524),
              )),
        ],
      ),
    );
  }
}
