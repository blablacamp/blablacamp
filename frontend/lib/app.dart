import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/notifications/notifications_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/favorites/cubit/favorites_cubit.dart';
import 'features/hikes/data/hikes_repository.dart';

class BlablacampApp extends StatelessWidget {
  const BlablacampApp({
    super.key,
    required this.router,
    required this.authRepository,
    required this.hikesRepository,
    required this.notifications,
  });

  final GoRouter router;
  final AuthRepository authRepository;
  final HikesRepository hikesRepository;
  final NotificationsService notifications;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: hikesRepository),
        RepositoryProvider.value(value: notifications),
      ],
      child: BlocProvider(
        create: (context) => FavoritesCubit(hikesRepository),
        child: MaterialApp.router(
          title: 'Blablacamp',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
  }
}
