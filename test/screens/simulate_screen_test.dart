import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cerebrosim/screens/simulate_screen.dart';
import 'package:cerebrosim/widgets/task_selector.dart';
import 'package:cerebrosim/widgets/neural_canvas.dart';
import 'package:cerebrosim/widgets/signal_plotter.dart';

void main() {
  testWidgets('SimulateScreen renders all main components', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SimulateScreen(),
        ),
      ),
    );

    expect(find.byType(TaskSelector), findsOneWidget);
    expect(find.byType(NeuralCanvas), findsOneWidget);
    expect(find.byType(SignalPlotter), findsOneWidget);
  });
}
