import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cerebrosim/models/neuron.dart';
import 'package:cerebrosim/models/synapse.dart';
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

  testWidgets('NeuralCanvas should handle multiple neuron types', (WidgetTester tester) async {
    const state = SimulationState(
      neurons: [
        Neuron(id: 'pf', type: 'Granular', threshold: 1, currentPotential: 0),
        Neuron(id: 'sc', type: 'SC', threshold: 1, currentPotential: 0.8),
        Neuron(id: 'bc', type: 'BC', threshold: 1, currentPotential: 0),
        Neuron(id: 'pc', type: 'Purkinje', threshold: 1, currentPotential: 1.2), // Spiking
        Neuron(id: 'dcn', type: 'DCN', threshold: 1, currentPotential: 0, actionGroup: 'test'),
      ],
      synapses: [
        Synapse(sourceId: 'pf', targetId: 'pc', weight: 0.5, learningRate: 0.1, targetType: 'PC'),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NeuralCanvas(
            state: state,
          ),
        ),
      ),
    );

    expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
  });
}
