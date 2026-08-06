import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shapes.dart';
import '../../auth/data/auth_repository.dart';
import '../../hikes/view/create_hike_page.dart';
import '../../requests/view/organizer_requests_page.dart';

/// Profile tab: identity, self-description (bio) with editing, and sign out.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  AuthRepository get _auth => context.read<AuthRepository>();
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await _auth.fetchMyProfile();
    if (!mounted) return;
    setState(() {
      _profile = p;
      _loading = false;
    });
  }

  String get _name {
    final n = _profile?['display_name'] as String?;
    if (n != null && n.isNotEmpty) return n;
    return _auth.currentUser?.email ?? 'Мандрівник';
  }

  String? get _bio => _profile?['bio'] as String?;

  Future<void> _edit() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditProfileSheet(
        auth: _auth,
        initialName: _name,
        initialBio: _bio ?? '',
      ),
    );
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accent))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Профіль',
                            style: GoogleFonts.unbounded(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            )),
                        if (_auth.isConfigured)
                          TextButton.icon(
                            onPressed: _edit,
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Редагувати'),
                            style: TextButton.styleFrom(
                                foregroundColor: AppColors.accent),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.divider,
                          child: Text(
                            _name.isNotEmpty
                                ? _name.substring(0, 1).toUpperCase()
                                : '?',
                            style: GoogleFonts.manrope(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_name,
                                  style: GoogleFonts.manrope(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  )),
                              if (user?.email != null)
                                Text(user!.email!,
                                    style: GoogleFonts.manrope(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    )),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('ПРО СЕБЕ',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: AppColors.textSecondary,
                        )),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: AppShapes.leaf,
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        (_bio != null && _bio!.isNotEmpty)
                            ? _bio!
                            : 'Розкажи про себе: який темп любиш, куди мрієш піти, що вмієш у горах. Це бачитимуть організатори.',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          height: 1.5,
                          color: (_bio != null && _bio!.isNotEmpty)
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _ActionTile(
                      icon: Icons.add_location_alt_outlined,
                      label: 'Створити похід',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const CreateHikePage())),
                    ),
                    const SizedBox(height: 10),
                    _ActionTile(
                      icon: Icons.inbox_outlined,
                      label: 'Заявки на мої походи',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const OrganizerRequestsPage())),
                    ),
                    const Spacer(),
                    if (_auth.isConfigured)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => _auth.signOut(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: AppColors.textSecondary, width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: AppShapes.leaf),
                          ),
                          child: Text('Вийти',
                              style: GoogleFonts.manrope(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              )),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({
    required this.auth,
    required this.initialName,
    required this.initialBio,
  });

  final AuthRepository auth;
  final String initialName;
  final String initialBio;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final _name = TextEditingController(text: widget.initialName);
  late final _bio = TextEditingController(text: widget.initialBio);
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.auth.updateMyProfile(
        displayName: _name.text.trim(),
        bio: _bio.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Редагувати профіль',
              style: GoogleFonts.unbounded(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 16),
          _label("Ім'я"),
          TextField(
            controller: _name,
            decoration: _dec('Як тебе звати'),
          ),
          const SizedBox(height: 16),
          _label('Про себе'),
          TextField(
            controller: _bio,
            maxLines: 4,
            maxLength: 300,
            decoration: _dec('Темп, досвід, що любиш у горах…'),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: Material(
              color: AppColors.accent,
              borderRadius: AppShapes.leaf,
              child: InkWell(
                borderRadius: AppShapes.leaf,
                onTap: _saving ? null : _save,
                child: Center(
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.cream),
                        )
                      : Text('Зберегти',
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

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t.toUpperCase(),
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF747A78),
            )),
      );

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
      );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    )),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
