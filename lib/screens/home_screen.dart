import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/simulation_provider.dart';
import '../widgets/neural_canvas.dart';
import '../models/simulation_state.dart';
import '../models/neuron.dart';
import '../models/synapse.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize with some mock data for visualization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(simulationProvider.notifier).initialize(
        const SimulationState(
          neurons: [
            Neuron(id: 'n1', type: 'Granular', threshold: 10, currentPotential: 0, x: 100, y: 100),
            Neuron(id: 'n2', type: 'Purkinje', threshold: 15, currentPotential: 0, x: 300, y: 200),
          ],
          synapses: [
            Synapse(sourceId: 'n1', targetId: 'n2', weight: 5.0, learningRate: 0.1),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final simulationState = ref.watch(simulationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CerebroSim Lab'),
        actions: [
          IconButton(
            icon: Icon(ref.watch(simulationProvider.notifier).isRunning 
                ? Icons.stop 
                : Icons.play_arrow),
            onPressed: () {
              final notifier = ref.read(simulationProvider.notifier);
              if (notifier.isRunning) {
                notifier.stop();
              } else {
                notifier.start();
              }
              setState(() {}); // Rebuild to update icon
            },
          ),
        ],
      ),
      body: InteractiveViewer(
        boundaryMargin: const EdgeInsets.all(double.infinity),
        minScale: 0.1,
        maxScale: 5.0,
        child: SizedBox(
          width: 2000,
          height: 2000,
          child: NeuralCanvas(state: simulationState),
        ),
      ),
    );
  }
}
