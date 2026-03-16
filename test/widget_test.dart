import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cerebrosim/main.dart';

void main() {
  testWidgets('App initialization smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // We wrap it in ProviderScope because it's required for Riverpod
    await tester.pumpWidget(
      const ProviderScope(
        child: CerebroSimApp(),
      ),
    );

    // Verify that our home screen displays the correct title.
    expect(find.text('CerebroSim Lab'), findsOneWidget);
  });
}
