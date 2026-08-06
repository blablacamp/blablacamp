import 'package:flutter_test/flutter_test.dart';

import 'package:blablacamp/app.dart';
import 'package:blablacamp/core/notifications/notifications_service.dart';
import 'package:blablacamp/core/router/app_router.dart';
import 'package:blablacamp/features/auth/data/auth_repository.dart';
import 'package:blablacamp/features/hikes/data/hikes_repository.dart';

void main() {
  testWidgets('onboarding renders brand, slogan and CTA', (tester) async {
    final auth = AuthRepository();
    await tester.pumpWidget(BlablacampApp(
      router: createRouter(auth),
      authRepository: auth,
      hikesRepository: HikesRepository(),
      notifications: NotificationsService(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('BlaBlaCamp'), findsOneWidget);
    expect(find.text('Хочу приєднатися'), findsOneWidget);
    expect(find.text('Хочу зібрати групу'), findsOneWidget);
    expect(find.text('Подивитися, хто куди йде'), findsOneWidget);
  });
}
