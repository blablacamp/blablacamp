import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/web/widgets/web_chrome.dart';

/// Simple static content pages (rules / safety / contact) reachable from the
/// web footer.
class InfoPage extends StatelessWidget {
  const InfoPage({super.key, required this.topic});

  final String topic;

  static const _content = <String, (String, List<String>)>{
    'rules': (
      'Правила спільноти',
      [
        'BlaBlaCamp — про повагу й довіру. Ми зводимо людей для спільних походів, тож базові домовленості прості.',
        'Будь чесним в описі походу: маршрут, складність, дати й що входить.',
        'Поважай учасників і організатора. Домовляйся про витрати заздалегідь.',
        'Скасовуєш участь — попередь групу якомога раніше.',
        'Жодних дискримінації, спаму чи небезпечної поведінки на маршруті.',
      ],
    ),
    'safety': (
      'Безпека в горах',
      [
        'Гори — це серйозно. Оціни свій рівень і не переоцінюй сили.',
        'Перевір прогноз погоди перед виходом і май запасний план.',
        'Бери відповідне спорядження — скористайся чеклистом у застосунку.',
        'Повідом близьким свій маршрут і орієнтовний час повернення.',
        'У разі небезпеки телефонуй 112 (єдиний номер екстреної допомоги).',
      ],
    ),
    'contact': (
      'Контакти',
      [
        'Питання, ідеї чи проблеми? Ми на зв’язку.',
        'Email: hello@blablacamp.com',
        'Ми відповідаємо протягом кількох робочих днів.',
      ],
    ),
  };

  @override
  Widget build(BuildContext context) {
    final (title, paragraphs) = _content[topic] ?? _content['contact']!;
    return WebChrome(
      footer: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(title,
                style: GoogleFonts.unbounded(
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                )),
            const SizedBox(height: 24),
            for (final p in paragraphs)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(p,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      height: 1.6,
                      color: AppColors.textSecondary,
                    )),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
