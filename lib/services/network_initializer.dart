import '../models/neuron.dart';
import '../models/synapse.dart';
import '../models/simulation_state.dart';

class NetworkInitializer {
  static SimulationState createRLMockNetwork() {
    final neurons = <Neuron>[];
    final synapses = <Synapse>[];

    // 1. Parallel Fiber neurons (PF / Granular) - Top Layer (Y=100)
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

    // 2. Basket Cells (BC - Lateral Inhibition) - Middle Layer (Y=250)
    for (int i = 0; i < 5; i++) {
      neurons.add(Neuron(
        id: 'bc_$i',
        type: 'BC',
        threshold: 2.0,
        currentPotential: 0.0,
        x: 250.0,
        y: 150.0 + (i * 100.0),
      ));
    }

    // 3. Purkinje Cells (Actor) - Below BCs (Y=450)
    neurons.add(const Neuron(
      id: 'pc_1',
      type: 'Purkinje',
      threshold: 5.0,
      currentPotential: 0.0,
      x: 450.0,
      y: 400.0,
    ));
    neurons.add(const Neuron(
      id: 'pc_2',
      type: 'Purkinje',
      threshold: 5.0,
      currentPotential: 0.0,
      x: 450.0,
      y: 540.0,
    ));

    // 4. Stellate Cell (Critic) - Same level as BCs (Y=250)
    neurons.add(const Neuron(
      id: 'sc_1',
      type: 'SC',
      threshold: 3.0,
      currentPotential: 0.0,
      x: 450.0,
      y: 150.0,
    ));

    // 5. DCN Cells (Output Actions) - Bottom Layer (Y=650)
    neurons.add(const Neuron(
      id: 'dcn_open',
      type: 'DCN',
      threshold: 2.0,
      currentPotential: 0.0,
      x: 750.0,
      y: 300.0,
      actionGroup: 'antiopen',
    ));
    neurons.add(const Neuron(
      id: 'dcn_close',
      type: 'DCN',
      threshold: 2.0,
      currentPotential: 0.0,
      x: 750.0,
      y: 500.0,
      actionGroup: 'anticlose',
    ));

    // 6. Connect PFs (Excitatory +) to BC, PC, and SC
    for (int i = 0; i < 10; i++) {
      // PF to PC_1 and PC_2
      synapses.add(Synapse(
        sourceId: 'pf_$i',
        targetId: 'pc_1',
        weight: 0.5,
        learningRate: 0.05,
        targetType: 'PC',
      ));
      synapses.add(Synapse(
        sourceId: 'pf_$i',
        targetId: 'pc_2',
        weight: 0.5,
        learningRate: 0.05,
        targetType: 'PC',
      ));
      
      // PF to SC_1 (Critic update)
      synapses.add(Synapse(
        sourceId: 'pf_$i',
        targetId: 'sc_1',
        weight: 0.2,
        learningRate: 0.02,
        targetType: 'SC',
      ));
      
      // PF to nearest BC
      synapses.add(Synapse(
        sourceId: 'pf_$i',
        targetId: 'bc_${(i / 2).floor()}',
        weight: 0.3,
        learningRate: 0.0,
        targetType: 'BC',
      ));
    }

    // 7. Inhibitory Synapses (Negative Weights)
    // BC to PC inhibition
    for (int i = 0; i < 5; i++) {
      synapses.add(Synapse(
        sourceId: 'bc_$i',
        targetId: 'pc_1',
        weight: -1.0, // Inhibitory
        learningRate: 0.0,
        targetType: 'PC',
      ));
      synapses.add(Synapse(
        sourceId: 'bc_$i',
        targetId: 'pc_2',
        weight: -1.0, // Inhibitory
        learningRate: 0.0,
        targetType: 'PC',
      ));
    }

    // Purkinje to DCN inhibition (PC always inhibits DCN)
    synapses.add(const Synapse(
      sourceId: 'pc_1',
      targetId: 'dcn_open',
      weight: -2.0, // Inhibitory
      learningRate: 0.0,
      targetType: 'DCN',
    ));
    synapses.add(const Synapse(
      sourceId: 'pc_2',
      targetId: 'dcn_close',
      weight: -2.0, // Inhibitory
      learningRate: 0.0,
      targetType: 'DCN',
    ));

    return SimulationState(neurons: neurons, synapses: synapses);
  }
}
