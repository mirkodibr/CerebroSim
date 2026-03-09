import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cerebrosim/models/neuron.dart';
import 'package:cerebrosim/models/simulation_state.dart';
import 'package:cerebrosim/widgets/neural_canvas.dart';

void main() {
  testWidgets('NeuralCanvas should render CustomPaint', (WidgetTester tester) async {
    const canvasKey = Key('neural_canvas');
    const state = SimulationState(
      neurons: [
        Neuron(id: 'n1', type: 'G', threshold: 10, currentPotential: 0, x: 50, y: 50),
      ],
      synapses: [],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NeuralCanvas(
            key: canvasKey,
            state: state,
          ),
        ),
      ),
    );

    expect(find.byKey(canvasKey), findsOneWidget);
    expect(find.descendant(of: find.byKey(canvasKey), matching: find.byType(CustomPaint)), findsOneWidget);
  });
}
