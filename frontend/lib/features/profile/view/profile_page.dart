import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shapes.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../../core/widgets/star_rating.dart';
import '../../auth/data/auth_repository.dart';
import '../../hikes/data/hikes_repository.dart';
import '../../hikes/data/models/review.dart';
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
  HikesRepository get _hikes => context.read<HikesRepository>();
  Map<String, dynamic>? _profile;
  List<Review> _reviews = const [];
  bool _loading = true;
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await _auth.fetchMyProfile();
    final uid = _auth.currentUser?.id;
    final reviews = uid == null ? <Review>[] : await _hikes.fetchReviews(uid);
    if (!mounted) return;
    setState(() {
      _profile = p;
      _reviews = reviews;
      _loading = false;
    });
  }

  double get _avgRating => _reviews.isEmpty
      ? 0
      : _reviews.map((r) => r.rating).reduce((a, b) => a + b) / _reviews.length;

  Future<void> _pickAvatar() async {
    final messenger = ScaffoldMessenger.of(context);
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (picked == null) return;
    setState(() => _uploadingAvatar = true);
    try {
      final bytes = await picked.readAsBytes();
      final ext = picked.name.split('.').last.toLowerCase();
      await _auth.uploadAvatar(bytes, ext: ext == 'png' ? 'png' : 'jpg');
      await _load();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Не вдалося: $e')));
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  String get _name {
    final n = _profile?['display_name'] as String?;
    if (n != null && n.isNotEmpty) return n;
    return _auth.currentUser?.email ?? 'Мандрівник';
  }

  String? get _bio => _profile?['bio'] as String?;
  String? get _avatarUrl => _profile?['avatar_url'] as String?;

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
              : ListView(
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
                        _AvatarPicker(
                          url: _avatarUrl,
                          letter: _name.isNotEmpty
                              ? _name.substring(0, 1).toUpperCase()
                              : '?',
                          uploading: _uploadingAvatar,
                          onTap: _pickAvatar,
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
                              if (_reviews.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    StarRating(value: _avgRating, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                        '${_avgRating.toStringAsFixed(1)} · ${_reviews.length} відгук(ів)',
                                        style: GoogleFonts.manrope(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        )),
                                  ],
                                ),
                              ],
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
                    const SizedBox(height: 24),
                    if (_reviews.isNotEmpty) ...[
                      Text('ВІДГУКИ',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors.textSecondary,
                          )),
                      const SizedBox(height: 8),
                      for (final r in _reviews) _ReviewTile(review: r),
                      const SizedBox(height: 24),
                    ],
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

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.url,
    required this.letter,
    required this.uploading,
    required this.onTap,
  });

  final String? url;
  final String letter;
  final bool uploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;
    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: Stack(
        children: [
          Container(
            width: 64,
            height: 64,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: AppColors.divider,
              shape: BoxShape.circle,
            ),
            child: uploading
                ? const Center(
                    child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.accent)))
                : hasUrl
                    ? Image.network(url!, fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _letter())
                    : _letter(),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt,
                  size: 12, color: AppColors.cream),
            ),
          ),
        ],
      ),
    );
  }

  Widget _letter() => Center(
        child: Text(letter,
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            )),
      );
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});
  final Review review;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (review.author != null)
                AvatarCircle(profile: review.author!, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(review.author?.displayName ?? 'Мандрівник',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    )),
              ),
              StarRating(value: review.rating.toDouble(), size: 14),
            ],
          ),
          if (review.body != null && review.body!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.body!,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.textSecondary,
                )),
          ],
        ],
      ),
    );
  }
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
