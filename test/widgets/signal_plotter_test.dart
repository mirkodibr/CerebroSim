import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cerebrosim/widgets/signal_plotter.dart';

void main() {
  testWidgets('SignalPlotter renders legend and CustomPaint', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SignalPlotter(),
          ),
        ),
      ),
    );

    // Verify Legend items
    expect(find.text('Critic'), findsOneWidget);
    expect(find.text('Actual'), findsOneWidget);
    
    // Verify CustomPaint is present
    expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
  });
}
