import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shapes.dart';
import '../../../core/utils/date_format.dart';
import '../data/hikes_repository.dart';
import '../data/models/hike.dart';

/// Campmaker flow: create a new hike (guided or shared).
class CreateHikePage extends StatefulWidget {
  const CreateHikePage({super.key});

  @override
  State<CreateHikePage> createState() => _CreateHikePageState();
}

class _CreateHikePageState extends State<CreateHikePage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _region = TextEditingController();
  final _location = TextEditingController();
  final _summary = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();

  HikeType _type = HikeType.shared;
  HikeDifficulty _difficulty = HikeDifficulty.moderate;
  DateTimeRange? _dates;
  int _maxParticipants = 8;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_title, _region, _location, _summary, _description, _price]) {
      c.dispose();
    }
    super.dispose();
  }

  int get _durationDays => _dates == null
      ? 1
      : _dates!.end.difference(_dates!.start).inDays + 1;

  Future<void> _pickDates() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime(2027, 12, 31),
      initialDateRange: _dates,
    );
    if (range != null) setState(() => _dates = range);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final priceCents = _type == HikeType.guided
          ? ((int.tryParse(_price.text.trim()) ?? 0) * 100)
          : 0;
      await context.read<HikesRepository>().createHike(
            type: _type,
            title: _title.text.trim(),
            summary: _summary.text.trim().isEmpty ? null : _summary.text.trim(),
            description:
                _description.text.trim().isEmpty ? null : _description.text.trim(),
            region: _region.text.trim().isEmpty ? null : _region.text.trim(),
            location:
                _location.text.trim().isEmpty ? null : _location.text.trim(),
            startDate: _dates?.start,
            endDate: _dates?.end,
            difficulty: _difficulty,
            durationDays: _durationDays,
            maxParticipants: _maxParticipants,
            priceCents: priceCents,
          );
      messenger.showSnackBar(
        const SnackBar(content: Text('Похід створено! Тепер шукай учасників.')),
      );
      navigator.pop(true);
    } catch (e) {
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text('Не вдалося створити: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text('Новий похід',
            style: GoogleFonts.manrope(
                fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            _TypeSelector(
              value: _type,
              onChanged: (t) => setState(() => _type = t),
            ),
            const SizedBox(height: 20),
            _Label('Назва'),
            _Field(
              controller: _title,
              hint: 'Напр. «Говерла на світанку»',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Вкажи назву' : null,
            ),
            const SizedBox(height: 16),
            _Label('Регіон'),
            _Field(controller: _region, hint: 'Карпати'),
            const SizedBox(height: 16),
            _Label('Старт (місто/точка збору)'),
            _Field(controller: _location, hint: 'Львів'),
            const SizedBox(height: 16),
            _Label('Дати'),
            _PickerTile(
              icon: Icons.calendar_today,
              text: _dates == null
                  ? 'Обрати дати'
                  : '${formatDateRange(_dates!.start, _dates!.end)}  ·  $_durationDays дн.',
              onTap: _pickDates,
            ),
            const SizedBox(height: 16),
            _Label('Складність'),
            _DifficultySelector(
              value: _difficulty,
              onChanged: (d) => setState(() => _difficulty = d),
            ),
            const SizedBox(height: 16),
            _Label('Розмір групи'),
            _Stepper(
              value: _maxParticipants,
              min: 2,
              max: 30,
              onChanged: (v) => setState(() => _maxParticipants = v),
            ),
            if (_type == HikeType.guided) ...[
              const SizedBox(height: 16),
              _Label('Ціна з особи, ₴'),
              _Field(
                controller: _price,
                hint: '2400',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
            const SizedBox(height: 16),
            _Label('Короткий опис'),
            _Field(
              controller: _summary,
              hint: 'Один рядок про суть походу',
            ),
            const SizedBox(height: 16),
            _Label('Деталі'),
            _Field(
              controller: _description,
              hint: 'Маршрут, темп, що взяти…',
              maxLines: 4,
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
                  onTap: _saving ? null : _submit,
                  child: Center(
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.cream),
                          )
                        : Text('Опублікувати похід',
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
    );
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.value, required this.onChanged});
  final HikeType value;
  final ValueChanged<HikeType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _typeCard(HikeType.shared, 'Спільний', 'Без оплати, ділимо витрати'),
        const SizedBox(width: 12),
        _typeCard(HikeType.guided, 'З гідом', 'Платний, ти ведеш групу'),
      ],
    );
  }

  Widget _typeCard(HikeType t, String title, String subtitle) {
    final selected = value == t;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(t),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? AppColors.cream : AppColors.cream.withValues(alpha: 0.5),
            borderRadius: AppShapes.leafOf(16, 6),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  )),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultySelector extends StatelessWidget {
  const _DifficultySelector({required this.value, required this.onChanged});
  final HikeDifficulty value;
  final ValueChanged<HikeDifficulty> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final d in HikeDifficulty.values)
          ChoiceChip(
            label: Text(d.label),
            selected: value == d,
            onSelected: (_) => onChanged(d),
            labelStyle: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: value == d ? AppColors.cream : AppColors.textPrimary,
            ),
            selectedColor: AppColors.accent,
            backgroundColor: AppColors.cream,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.divider),
            ),
            showCheckmark: false,
          ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove),
          ),
          Text('$value осіб',
              style: GoogleFonts.manrope(
                  fontSize: 15, fontWeight: FontWeight.w700)),
          IconButton(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile(
      {required this.icon, required this.text, required this.onTap});
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Text(text,
                style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text.toUpperCase(),
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF747A78),
            )),
      );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.inputFormatters,
  });
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      style: GoogleFonts.manrope(fontSize: 15, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.cream,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
      ),
    );
  }
}
