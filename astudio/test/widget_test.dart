// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:astudio/app/app.dart';
import 'package:astudio/features/auth/application/auth_controller.dart';
import 'package:astudio/features/auth/application/auth_state.dart';
import 'package:astudio/features/profile/domain/profile_status.dart';
import 'package:astudio/features/profile/domain/user_profile.dart';
import 'package:astudio/features/profile/domain/user_role.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_FakeAuthController.new),
        ],
        child: const App(),
      ),
    );

    // Wait for the app to initialize
    await tester.pumpAndSettle();

    // The app should render without errors
    expect(find.byType(App), findsOneWidget);
  });
}

class _FakeAuthController extends AuthController {
  @override
  AuthViewState build() {
    const profile = UserProfile(
      id: 'test-user',
      email: 'test@example.com',
      fullName: 'Test User',
      role: UserRole.artist,
      status: ProfileStatus.approved,
    );
    return const AuthViewState(
      status: AuthStatus.authenticated,
      profile: profile,
    );
  }
}
