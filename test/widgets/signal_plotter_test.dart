import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cerebrosim/widgets/signal_plotter.dart';
import 'package:cerebrosim/providers/environment_provider.dart';

void main() {
  testWidgets('SignalPlotter renders and draws based on history', (WidgetTester tester) async {
    final history = [
      HistoryPoint(1.0, 0.0),
      HistoryPoint(0.0, 1.0),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SignalPlotter(history: history),
        ),
      ),
    );

    // Verify Title (Updated in step 24 to 'Actor-Critic Performance')
    expect(find.text('Actor-Critic Performance'), findsOneWidget);
    
    // Verify CustomPaint is present
    expect(find.byType(CustomPaint), findsAtLeast(1));
    
    // Basic rendering check: Ensure the container exists
    expect(find.byType(Container), findsAtLeast(1));
  });

  testWidgets('SignalPlotter handles empty history', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SignalPlotter(history: []),
        ),
      ),
    );

    expect(find.text('Actor-Critic Performance'), findsOneWidget);
    expect(find.byType(CustomPaint), findsAtLeast(1));
  });
}
