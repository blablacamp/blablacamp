import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shapes.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../hikes/data/hikes_repository.dart';
import '../../hikes/data/models/message.dart';
import '../../hikes/data/models/profile_ref.dart';
import '../cubit/chat_cubit.dart';

/// Per-hike group chat.
class ChatPage extends StatelessWidget {
  const ChatPage({
    super.key,
    required this.hikeId,
    required this.title,
    required this.repository,
  });

  final String hikeId;
  final String title;
  final HikesRepository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatCubit(repository, hikeId: hikeId),
      child: _ChatView(
        title: title,
        hikeId: hikeId,
        repository: repository,
        myId: repository.currentUserId,
      ),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView({
    required this.title,
    required this.hikeId,
    required this.repository,
    this.myId,
  });
  final String title;
  final String hikeId;
  final HikesRepository repository;
  final String? myId;

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  List<ProfileRef> _participants = const [];
  List<ProfileRef> _mentionMatches = const [];

  @override
  void initState() {
    super.initState();
    widget.repository.fetchApprovedParticipants(widget.hikeId).then((p) {
      if (mounted) setState(() => _participants = p);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// If the caret sits inside a trailing "@query" token, returns the query.
  String? _mentionQuery() {
    final sel = _controller.selection;
    if (!sel.isValid || !sel.isCollapsed) return null;
    final upto = _controller.text.substring(0, sel.baseOffset);
    final at = upto.lastIndexOf('@');
    if (at < 0) return null;
    // '@' must start a word and have no whitespace after it.
    if (at > 0 && !RegExp(r'\s').hasMatch(upto[at - 1])) return null;
    final query = upto.substring(at + 1);
    if (query.contains(RegExp(r'\s'))) return null;
    return query;
  }

  void _onComposerChanged(String _) {
    context.read<ChatCubit>().notifyTyping();
    final q = _mentionQuery();
    final matches = q == null
        ? <ProfileRef>[]
        : _participants
            .where((p) =>
                p.displayName.toLowerCase().contains(q.toLowerCase()))
            .take(5)
            .toList();
    setState(() => _mentionMatches = matches);
  }

  void _insertMention(ProfileRef p) {
    final sel = _controller.selection;
    final text = _controller.text;
    final upto = text.substring(0, sel.baseOffset);
    final at = upto.lastIndexOf('@');
    if (at < 0) return;
    final name = p.displayName.split(' ').first;
    final before = text.substring(0, at);
    final after = text.substring(sel.baseOffset);
    final mention = '@$name ';
    final inserted = '$before$mention$after';
    _controller.value = TextEditingValue(
      text: inserted,
      selection: TextSelection.collapsed(offset: before.length + mention.length),
    );
    setState(() => _mentionMatches = const []);
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut);
      }
    });
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    context.read<ChatCubit>().send(text);
    _controller.clear();
  }

  Future<void> _pickImage() async {
    final cubit = context.read<ChatCubit>();
    final x = await ImagePicker().pickImage(
        source: ImageSource.gallery, maxWidth: 1600, imageQuality: 82);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    await cubit.sendAttachment(
        bytes: bytes,
        filename: x.name,
        isImage: true,
        contentType: 'image/jpeg');
  }

  Future<void> _pickFile() async {
    final cubit = context.read<ChatCubit>();
    final res = await FilePicker.platform.pickFiles(withData: true);
    final f = res?.files.firstOrNull;
    if (f?.bytes == null) return;
    await cubit.sendAttachment(
        bytes: f!.bytes!, filename: f.name, isImage: false);
  }

  Future<void> _shareContact() async {
    final cubit = context.read<ChatCubit>();
    final result = await showDialog<({String name, String handle})>(
      context: context,
      builder: (_) => _ContactDialog(defaultName: widget.repository.currentUserName),
    );
    if (result == null) return;
    await cubit.sendContact(result.name, result.handle);
  }

  /// Presents [content] as a centered dialog on wide (web) layouts, or a
  /// bottom sheet on mobile.
  Future<void> _present(Widget content, {double maxWidth = 420}) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    if (wide) {
      return showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: AppColors.cream,
          shape: RoundedRectangleBorder(borderRadius: AppShapes.leaf),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: content,
          ),
        ),
      );
    }
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(child: content),
    );
  }

  void _openAttachMenu() {
    _present(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _attachTile(Icons.photo_outlined, 'Фото', () {
            Navigator.pop(context);
            _pickImage();
          }),
          _attachTile(Icons.attach_file, 'Файл', () {
            Navigator.pop(context);
            _pickFile();
          }),
          _attachTile(Icons.person_outline, 'Поділитися контактом', () {
            Navigator.pop(context);
            _shareContact();
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _attachTile(IconData icon, String label, VoidCallback onTap) => ListTile(
        leading: Icon(icon, color: AppColors.accent),
        title: Text(label,
            style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        onTap: onTap,
      );

  void _showParticipants() async {
    final members = await widget.repository.fetchApprovedParticipants(widget.hikeId);
    if (!mounted) return;
    _present(
      Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Учасники (${members.length})',
                style: GoogleFonts.unbounded(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            if (members.isEmpty)
              Text('Поки лише ти.',
                  style: GoogleFonts.manrope(color: AppColors.textSecondary)),
            for (final p in members)
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/user/${p.id}');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    AvatarCircle(profile: p, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(p.displayName,
                          style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textSecondary, size: 20),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                )),
            Text('Груповий чат походу',
                style: GoogleFonts.manrope(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Учасники',
            onPressed: _showParticipants,
            icon: const Icon(Icons.group_outlined),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatCubit, ChatState>(
              listenWhen: (a, b) => a.messages.length != b.messages.length,
              listener: (context, state) => _jumpToBottom(),
              builder: (context, state) {
                if (state.status == ChatStatus.loading) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.accent));
                }
                if (state.messages.isEmpty) {
                  return Center(
                    child: Text('Напишіть першими 👋',
                        style: GoogleFonts.manrope(
                            color: AppColors.textSecondary)),
                  );
                }
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: state.messages.length,
                  itemBuilder: (context, i) {
                    final m = state.messages[i];
                    return _Bubble(message: m, mine: m.senderId == widget.myId);
                  },
                );
              },
            ),
          ),
          if (_mentionMatches.isNotEmpty)
            _MentionStrip(matches: _mentionMatches, onPick: _insertMention),
          BlocBuilder<ChatCubit, ChatState>(
            buildWhen: (a, b) => a.typingName != b.typingName,
            builder: (context, state) => _TypingIndicator(name: state.typingName),
          ),
          _Composer(
            controller: _controller,
            onSend: _send,
            onAttach: _openAttachMenu,
            onChanged: _onComposerChanged,
          ),
        ],
          ),
        ),
      ),
    );
  }
}

class _MentionStrip extends StatelessWidget {
  const _MentionStrip({required this.matches, required this.onPick});
  final List<ProfileRef> matches;
  final ValueChanged<ProfileRef> onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cream,
      constraints: const BoxConstraints(maxHeight: 180),
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final p in matches)
            ListTile(
              dense: true,
              leading: AvatarCircle(profile: p, size: 30),
              title: Text('@${p.displayName}',
                  style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              onTap: () => onPick(p),
            ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator({this.name});
  final String? name;

  @override
  Widget build(BuildContext context) {
    if (name == null) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
        child: Text('$name пише…',
            style: GoogleFonts.manrope(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary)),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});
  final Message message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final fg = mine ? AppColors.cream : AppColors.textPrimary;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: message.kind == MessageKind.image
            ? const EdgeInsets.all(4)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth:
                (MediaQuery.sizeOf(context).width * 0.75).clamp(0, 460)),
        decoration: BoxDecoration(
          color: mine ? AppColors.accent : AppColors.cream,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(mine ? 14 : 4),
            bottomRight: Radius.circular(mine ? 4 : 14),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!mine && message.sender != null)
              Padding(
                padding: EdgeInsets.only(
                    left: message.kind == MessageKind.image ? 10 : 0,
                    top: message.kind == MessageKind.image ? 6 : 0,
                    bottom: 2),
                child: Text(message.sender!.displayName,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    )),
              ),
            _content(context, fg),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, Color fg) {
    switch (message.kind) {
      case MessageKind.image:
        return GestureDetector(
          onTap: () => _openImage(context, message.attachmentUrl!),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              message.attachmentUrl!,
              width: 220,
              fit: BoxFit.cover,
              loadingBuilder: (c, w, p) => p == null
                  ? w
                  : const SizedBox(
                      width: 220,
                      height: 160,
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.accent, strokeWidth: 2))),
              errorBuilder: (c, e, s) =>
                  const SizedBox(width: 220, height: 80, child: Icon(Icons.broken_image)),
            ),
          ),
        );
      case MessageKind.file:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file_outlined, size: 20, color: fg),
            const SizedBox(width: 8),
            Flexible(
              child: Text(message.attachmentName ?? 'Файл',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                      fontSize: 14, fontWeight: FontWeight.w600, color: fg)),
            ),
          ],
        );
      case MessageKind.contact:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.contact_phone_outlined, size: 20, color: fg),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message.contactName ?? 'Контакт',
                    style: GoogleFonts.manrope(
                        fontSize: 14, fontWeight: FontWeight.w700, color: fg)),
                if (message.contactHandle != null)
                  Text(message.contactHandle!,
                      style: GoogleFonts.ibmPlexMono(
                          fontSize: 12,
                          color: mine
                              ? AppColors.cream
                              : AppColors.textSecondary)),
              ],
            ),
          ],
        );
      case MessageKind.text:
        return _MentionText(text: message.body, mine: mine);
    }
  }

  void _openImage(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: InteractiveViewer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(url),
          ),
        ),
      ),
    );
  }
}

/// Renders message text with @mentions highlighted.
class _MentionText extends StatelessWidget {
  const _MentionText({required this.text, required this.mine});
  final String text;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final fg = mine ? AppColors.cream : AppColors.textPrimary;
    final base = GoogleFonts.manrope(fontSize: 14, color: fg);
    final spans = <TextSpan>[];
    final re = RegExp(r'@[\wА-Яа-яЇїІіЄєҐґ]+');
    var last = 0;
    for (final m in re.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start), style: base));
      }
      spans.add(TextSpan(
        text: m.group(0),
        style: base.copyWith(
          fontWeight: FontWeight.w700,
          color: mine ? AppColors.cream : AppColors.accent,
        ),
      ));
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last), style: base));
    }
    return RichText(text: TextSpan(children: spans));
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onSend,
    required this.onAttach,
    required this.onChanged,
  });
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      padding: EdgeInsets.fromLTRB(
          8, 8, 12, 8 + MediaQuery.paddingOf(context).bottom),
      child: Row(
        children: [
          IconButton(
            onPressed: onAttach,
            icon: const Icon(Icons.add_circle_outline, color: AppColors.accent),
            tooltip: 'Додати',
          ),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.send,
              onChanged: onChanged,
              onSubmitted: (_) => onSend(),
              minLines: 1,
              maxLines: 4,
              style: GoogleFonts.manrope(
                  fontSize: 15, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Повідомлення…',
                filled: true,
                fillColor: AppColors.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.accent,
            borderRadius: AppShapes.leafOf(18, 6),
            child: InkWell(
              borderRadius: AppShapes.leafOf(18, 6),
              onTap: onSend,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.send, color: AppColors.cream, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactDialog extends StatefulWidget {
  const _ContactDialog({required this.defaultName});
  final String defaultName;

  @override
  State<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<_ContactDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.defaultName == 'Хтось' ? '' : widget.defaultName);
  final _handle = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _handle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cream,
      title: Text('Поділитися контактом',
          style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: "Ім'я"),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _handle,
            decoration: const InputDecoration(
                labelText: 'Телефон / @телеграм', hintText: '+380… або @nick'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Скасувати'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
          onPressed: () {
            final name = _name.text.trim();
            final handle = _handle.text.trim();
            if (name.isEmpty || handle.isEmpty) return;
            Navigator.pop(context, (name: name, handle: handle));
          },
          child: const Text('Надіслати'),
        ),
      ],
    );
  }
}
