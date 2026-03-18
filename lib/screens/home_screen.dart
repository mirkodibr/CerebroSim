import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/simulation_provider.dart';
import '../providers/signal_provider.dart';
import '../widgets/neural_canvas.dart';
import '../widgets/signal_plotter.dart';
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
            Neuron(id: 'n1', type: 'Granular', threshold: 1, currentPotential: 0, x: 100, y: 150),
            Neuron(id: 'n2', type: 'Purkinje', threshold: 5, currentPotential: 0, x: 300, y: 150),
          ],
          synapses: [
            Synapse(sourceId: 'n1', targetId: 'n2', weight: 0.5, learningRate: 0.05, targetType: 'PC'),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final simulationState = ref.watch(simulationProvider);
    final history = ref.watch(signalHistoryProvider);
    final isRunning = ref.watch(simulationProvider.notifier).isRunning;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CerebroSim Lab'),
        actions: [
          PopupMenuButton<SignalType>(
            icon: const Icon(Icons.waves),
            onSelected: (type) {
              ref.read(signalProvider.notifier).setType(type);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: SignalType.sine, child: Text('Sine Wave')),
              const PopupMenuItem(value: SignalType.step, child: Text('Step Signal')),
              const PopupMenuItem(value: SignalType.square, child: Text('Square Wave')),
            ],
          ),
          IconButton(
            icon: Icon(isRunning ? Icons.stop : Icons.play_arrow),
            onPressed: () {
              final notifier = ref.read(simulationProvider.notifier);
              if (notifier.isRunning) {
                notifier.stop();
              } else {
                notifier.start();
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(double.infinity),
            minScale: 0.1,
            maxScale: 5.0,
            child: SizedBox(
              width: 2000,
              height: 2000,
              child: NeuralCanvas(state: simulationState),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: SignalPlotter(history: history),
          ),
        ],
      ),
    );
  }
}
