import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/hikes/data/hikes_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_shapes.dart';

const _reasons = <({String value, String label})>[
  (value: 'scam', label: 'Шахрайство / обман'),
  (value: 'unsafe', label: 'Небезпечна поведінка'),
  (value: 'harassment', label: 'Домагання / образи'),
  (value: 'spam', label: 'Спам або реклама'),
  (value: 'other', label: 'Інше'),
];

/// Opens a modal to file a moderation report about a hike, user or message.
/// On wide (web) layouts this is a centered dialog; on mobile a bottom sheet.
Future<void> showReportSheet(
  BuildContext context, {
  required HikesRepository repository,
  required String targetType, // 'hike' | 'user' | 'message'
  required String targetId,
  String? hikeId,
  String? title,
}) {
  final content = _ReportSheet(
    repository: repository,
    targetType: targetType,
    targetId: targetId,
    hikeId: hikeId,
    title: title,
  );
  final wide = MediaQuery.sizeOf(context).width >= 900;
  if (wide) {
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: AppShapes.leaf),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: content,
        ),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => content,
  );
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({
    required this.repository,
    required this.targetType,
    required this.targetId,
    this.hikeId,
    this.title,
  });

  final HikesRepository repository;
  final String targetType;
  final String targetId;
  final String? hikeId;
  final String? title;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  String? _reason;
  final _details = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason == null) return;
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await widget.repository.addReport(
        targetType: widget.targetType,
        targetId: widget.targetId,
        hikeId: widget.hikeId,
        reason: _reason!,
        details: _details.text.trim().isEmpty ? null : _details.text.trim(),
      );
      navigator.pop();
      messenger.showSnackBar(const SnackBar(
          content: Text('Дякуємо. Ми розглянемо скаргу.')));
    } catch (e) {
      setState(() => _sending = false);
      messenger.showSnackBar(SnackBar(
          content: Text(e is StateError ? e.message : 'Не вдалося надіслати скаргу.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final subject = switch (widget.targetType) {
      'hike' => 'похід',
      'message' => 'повідомлення',
      _ => 'користувача',
    };
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Поскаржитися на $subject',
              style: GoogleFonts.unbounded(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              )),
          if (widget.title != null) ...[
            const SizedBox(height: 4),
            Text(widget.title!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                    fontSize: 13, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 16),
          for (final r in _reasons)
            _ReasonTile(
              label: r.label,
              selected: _reason == r.value,
              onTap: () => setState(() => _reason = r.value),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _details,
            maxLines: 3,
            style: GoogleFonts.manrope(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Деталі (необовʼязково)',
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: Material(
              color: _reason == null ? AppColors.divider : AppColors.accent,
              borderRadius: AppShapes.leaf,
              child: InkWell(
                borderRadius: AppShapes.leaf,
                onTap: (_reason == null || _sending) ? null : _submit,
                child: Center(
                  child: _sending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.cream))
                      : Text('Надіслати скаргу',
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
    );
  }
}

class _ReasonTile extends StatelessWidget {
  const _ReasonTile(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 22,
              color: selected ? AppColors.accent : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: AppColors.textPrimary,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
