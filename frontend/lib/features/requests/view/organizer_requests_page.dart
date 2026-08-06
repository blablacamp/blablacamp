import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../hikes/data/hikes_repository.dart';
import '../../hikes/data/models/join_request.dart';
import '../cubit/requests_cubit.dart';

/// Organizer view: incoming join requests across all hikes they organize.
class OrganizerRequestsPage extends StatelessWidget {
  const OrganizerRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => RequestsCubit(ctx.read<HikesRepository>()),
      child: const _RequestsView(),
    );
  }
}

class _RequestsView extends StatelessWidget {
  const _RequestsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text('Заявки на мої походи',
            style: GoogleFonts.manrope(
                fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: BlocBuilder<RequestsCubit, RequestsState>(
        builder: (context, state) {
          switch (state.status) {
            case RequestsStatus.loading:
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.accent));
            case RequestsStatus.error:
              return Center(
                child: Text('Не вдалося завантажити',
                    style: GoogleFonts.manrope(color: AppColors.textSecondary)),
              );
            case RequestsStatus.ready:
              if (state.requests.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inbox_outlined,
                          size: 40, color: AppColors.textSecondary),
                      const SizedBox(height: 12),
                      Text('Поки немає нових заявок',
                          style: GoogleFonts.manrope(
                              color: AppColors.textSecondary)),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: state.requests.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _RequestCard(
                  request: state.requests[i],
                  onDecide: (approve) => context
                      .read<RequestsCubit>()
                      .respond(state.requests[i], approve),
                ),
              );
          }
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.onDecide});
  final JoinRequest request;
  final void Function(bool approve) onDecide;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarCircle(profile: request.applicant, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.applicant.displayName,
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        )),
                    Text('хоче в «${request.hikeTitle}»',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onDecide(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Відхилити'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => onDecide(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.cream,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Прийняти'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
