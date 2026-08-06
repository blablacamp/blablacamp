import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/hike_list_tile.dart';
import '../../hikes/data/hikes_repository.dart';
import '../cubit/conversations_cubit.dart';
import 'chat_page.dart';

/// "Повідомлення" tab — one conversation per hike you're a member of.
class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => ConversationsCubit(ctx.read<HikesRepository>()),
      child: const _MessagesView(),
    );
  }
}

class _MessagesView extends StatelessWidget {
  const _MessagesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: BlocBuilder<ConversationsCubit, ConversationsState>(
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Повідомлення',
                      style: GoogleFonts.unbounded(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      )),
                  const SizedBox(height: 12),
                  Expanded(
                    child: switch (state.status) {
                      ConversationsStatus.loading => const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.accent)),
                      _ when state.hikes.isEmpty => _empty(),
                      _ => ListView.separated(
                          itemCount: state.hikes.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1, color: AppColors.divider),
                          itemBuilder: (context, i) {
                            final hike = state.hikes[i];
                            return HikeListTile(
                              hike: hike,
                              subtitle: 'Чат групи · ${hike.region ?? ''}',
                              trailing: const Icon(Icons.chevron_right,
                                  color: AppColors.textSecondary),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ChatPage(
                                    hikeId: hike.id,
                                    title: hike.title,
                                    repository: context.read<HikesRepository>(),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _empty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline,
                size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text('Приєднайся до походу — і тут зʼявиться чат групи',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(color: AppColors.textSecondary)),
          ],
        ),
      );
}
