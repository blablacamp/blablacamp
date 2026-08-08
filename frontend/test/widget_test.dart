import 'package:flutter_test/flutter_test.dart';

import 'package:blablacamp/app.dart';
import 'package:blablacamp/core/notifications/notifications_service.dart';
import 'package:blablacamp/core/router/app_router.dart';
import 'package:blablacamp/features/auth/data/auth_repository.dart';
import 'package:blablacamp/features/hikes/data/hikes_repository.dart';

void main() {
  testWidgets('intro carousel renders slide + CTA', (tester) async {
    final auth = AuthRepository();
    await tester.pumpWidget(BlablacampApp(
      router: createRouter(auth),
      authRepository: auth,
      hikesRepository: HikesRepository(),
      notifications: NotificationsService(),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Незнайомі на вокзалі'), findsOneWidget);
    expect(find.text('Далі'), findsOneWidget);
    expect(find.text('Пропустити'), findsOneWidget);
  });
}
