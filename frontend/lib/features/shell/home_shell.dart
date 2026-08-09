import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/notifications/notifications_service.dart';
import '../../core/theme/app_colors.dart';
import '../backpack/view/backpack_page.dart';
import '../favorites/view/favorites_page.dart';
import '../home/view/home_page.dart';
import '../messages/cubit/unread_cubit.dart';
import '../messages/view/messages_page.dart';
import '../profile/view/profile_page.dart';

/// Bottom-nav shell. Tabs mirror the Figma design:
/// Пошук / Обране / Мої походи / Повідомлення / Профіль.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.role});

  final String? role;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePromptPush());
  }

  Future<void> _maybePromptPush() async {
    final notifications = context.read<NotificationsService>();
    if (!notifications.isInitialized || notifications.permissionGranted) return;
    // Let the home screen settle before asking.
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted || notifications.permissionGranted) return;
    _promptPush(notifications);
  }

  void _promptPush(NotificationsService notifications) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Увімкнути сповіщення?'),
        content: const Text(
            'Щоб не пропустити заявки в похід і повідомлення від групи, '
            'дозволь push-сповіщення.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Пізніше'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              notifications.requestPermission();
            },
            child: const Text('Дозволити'),
          ),
        ],
      ),
    );
  }

  static const _tabs = <_TabSpec>[
    _TabSpec('Пошук', Icons.search, Icons.search),
    _TabSpec('Обране', Icons.favorite_border, Icons.favorite),
    _TabSpec('Мої походи', Icons.backpack_outlined, Icons.backpack),
    _TabSpec('Повідомлення', Icons.chat_bubble_outline, Icons.chat_bubble),
    _TabSpec('Профіль', Icons.person_outline, Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: IndexedStack(
        index: _index,
        children: [
          HomePage(
            onOpenSearch: () => context.push('/search'),
            onOpenHike: (hike) => context.push('/hike', extra: hike),
          ),
          const FavoritesPage(), // Обране
          const BackpackPage(), // Мої походи
          const MessagesPage(), // Повідомлення
          const ProfilePage(), // Профіль
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
          if (i == 3) context.read<UnreadCubit>().refresh();
        },
        destinations: [
          for (var i = 0; i < _tabs.length; i++)
            NavigationDestination(
              icon: _tabs[i].label == 'Повідомлення'
                  ? _UnreadBadge(child: Icon(_tabs[i].icon))
                  : Icon(_tabs[i].icon),
              selectedIcon: _tabs[i].label == 'Повідомлення'
                  ? _UnreadBadge(child: Icon(_tabs[i].selectedIcon))
                  : Icon(_tabs[i].selectedIcon),
              label: _tabs[i].label,
            ),
        ],
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Wraps an icon with the unread-conversations count badge.
class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final count = context.watch<UnreadCubit>().state;
    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      backgroundColor: AppColors.accent,
      child: child,
    );
  }
}
