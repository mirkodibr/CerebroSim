import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cerebrosim/screens/home_screen.dart';
import 'package:cerebrosim/widgets/neural_canvas.dart';

void main() {
  testWidgets('HomeScreen should render InteractiveViewer and NeuralCanvas', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    // Initial pump to run initState
    await tester.pump();
    // Second pump for addPostFrameCallback
    await tester.pump();
    // Additional pump for potential UI changes
    await tester.pumpAndSettle();

    expect(find.text('CerebroSim RL Lab'), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byType(NeuralCanvas), findsOneWidget);
  });
}
