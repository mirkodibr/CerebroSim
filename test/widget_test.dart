import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cerebrosim/main.dart';

void main() {
  testWidgets('App initialization smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: CerebroSimApp(),
      ),
    );

    // Wait for the auth state stream to emit its initial value (null)
    // and for any animations to complete.
    await tester.pumpAndSettle();

    // Should start at Login Screen
    expect(find.text('Login'), findsOneWidget);
  });
}
