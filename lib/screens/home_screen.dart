import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/simulation_provider.dart';
import '../providers/environment_provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resetToRLMock();
    });
  }

  void _resetToRLMock() {
    // 1. Generate 10 Parallel Fiber neurons (PF)
    final neurons = <Neuron>[];
    final synapses = <Synapse>[];

    for (int i = 0; i < 10; i++) {
      neurons.add(Neuron(
        id: 'pf_$i',
        type: 'Granular',
        threshold: 1.0,
        currentPotential: 0.0,
        x: 100.0,
        y: 100.0 + (i * 60.0),
      ));
    }

    // 2. Add Purkinje Cell (Actor)
    neurons.add(const Neuron(
      id: 'pc_1',
      type: 'Purkinje',
      threshold: 5.0,
      currentPotential: 0.0,
      x: 400.0,
      y: 370.0,
    ));

    // 3. Add Stellate Cell (Critic)
    neurons.add(const Neuron(
      id: 'sc_1',
      type: 'SC',
      threshold: 3.0,
      currentPotential: 0.0,
      x: 400.0,
      y: 150.0,
    ));

    // 4. Add DCN Cells (Output Actions)
    neurons.add(const Neuron(
      id: 'dcn_open',
      type: 'DCN',
      threshold: 2.0,
      currentPotential: 0.0,
      x: 700.0,
      y: 300.0,
      actionGroup: 'antiopen',
    ));
    neurons.add(const Neuron(
      id: 'dcn_close',
      type: 'DCN',
      threshold: 2.0,
      currentPotential: 0.0,
      x: 700.0,
      y: 440.0,
      actionGroup: 'anticlose',
    ));

    // 5. Connect PFs to PC and SC
    for (int i = 0; i < 10; i++) {
      synapses.add(Synapse(
        sourceId: 'pf_$i',
        targetId: 'pc_1',
        weight: 0.5,
        learningRate: 0.05,
        targetType: 'PC',
      ));
      synapses.add(Synapse(
        sourceId: 'pf_$i',
        targetId: 'sc_1',
        weight: 0.2,
        learningRate: 0.02,
        targetType: 'SC',
      ));
    }

    // 6. Connect PC to DCN (Inhibitory)
    // In our simplified model, we just use negative weights or handle it in logic.
    // Marr-Albus uses inhibition. Here, let's just connect them for visual.
    synapses.add(const Synapse(
      sourceId: 'pc_1',
      targetId: 'dcn_close',
      weight: 2.0,
      learningRate: 0.0,
      targetType: 'DCN',
    ));

    ref.read(simulationProvider.notifier).initialize(
      SimulationState(neurons: neurons, synapses: synapses),
    );
  }

  @override
  Widget build(BuildContext context) {
    final simulationState = ref.watch(simulationProvider);
    final history = ref.watch(signalHistoryProvider);
    final isRunning = ref.watch(simulationProvider.notifier).isRunning;
    final envState = ref.watch(environmentProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CerebroSim RL Lab'),
            Text(
              'Episode: ${envState.episodeNumber} | Step: ${envState.currentStep.toInt()}ms',
              style: const TextStyle(fontSize: 10, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetToRLMock,
            tooltip: 'Reset Simulation',
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
