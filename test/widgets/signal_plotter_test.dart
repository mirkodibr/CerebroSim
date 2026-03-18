import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cerebrosim/widgets/signal_plotter.dart';
import 'package:cerebrosim/providers/environment_provider.dart';

void main() {
  testWidgets('SignalPlotter renders and draws based on history from provider', (WidgetTester tester) async {
    final history = [
      HistoryPoint(1.0, 0.0),
      HistoryPoint(0.0, 1.0),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          signalHistoryProvider.overrideWith(() => MockSignalHistory(history)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SignalPlotter(),
          ),
        ),
      ),
    );

    // Verify Title
    expect(find.text('Actor-Critic Performance'), findsOneWidget);
    
    // Verify Legend items
    expect(find.text('Predicted'), findsOneWidget);
    expect(find.text('Actual CF'), findsOneWidget);
    
    // Verify CustomPaint is present
    expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
  });

  testWidgets('SignalPlotter handles empty history', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SignalPlotter(),
          ),
        ),
      ),
    );

    expect(find.text('Actor-Critic Performance'), findsOneWidget);
    expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
  });
}

class MockSignalHistory extends SignalHistoryNotifier {
  final List<HistoryPoint> initialHistory;
  MockSignalHistory(this.initialHistory);

  @override
  List<HistoryPoint> build() => initialHistory;
}
