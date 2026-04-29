import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cerebrosim/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cerebrosim/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class MockAuthNotifier extends AuthNotifier {
  @override
  FutureOr<User?> build() {
    return null;
  }
}

void main() {
  testWidgets('App initialization smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_complete': false});

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => MockAuthNotifier()),
        ],
        child: const CerebroSimApp(),
      ),
    );

    // Wait for the auth state stream to emit its initial value (null)
    // and for any animations to complete.
    await tester.pumpAndSettle();

    // Should start at Login Screen
    expect(find.text('Login'), findsOneWidget);
  });
}
