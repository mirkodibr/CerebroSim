import '../models/neuron_model.dart';
import '../models/synapse_model.dart';
import '../models/simulation_state.dart';

/// Helper class for setting up various neural network configurations.
/// 
/// It centralizes the logic for creating the initial neurons and their 
/// synaptic connections for specific cerebellar tasks.
class NetworkInitializer {
  /// Creates a mock cerebellar network suitable for reinforcement learning tasks.
  /// 
  /// The network contains:
  /// - **10 Parallel Fibers (GC):** Provide the sensory input (Context).
  /// - **5 Basket Cells (BC):** Provide lateral inhibition to Purkinje Cells.
  /// - **2 Purkinje Cells (PC):** The main integrative unit, inhibitory to DCN.
  /// - **1 Stellate Cell (SC):** Provides local inhibition within the molecular layer.
  /// - **2 Deep Cerebellar Nuclei (DCN):** The output of the circuit.
  /// 
  /// Synaptic setup:
  /// - GC -> PC, BC, SC (Excitatory)
  /// - BC -> PC (Inhibitory)
  /// - PC -> DCN (Inhibitory)
  /// 
  /// All weights are initialized with standard values (0.2 - 0.5 for excitatory,
  /// -1.0 to -2.0 for inhibitory) to allow for subsequent plasticity.
  static SimulationState createRLMockNetwork() {
    final neurons = <NeuronModel>[];
    final synapses = <SynapseModel>[];

    // 1. Parallel Fiber neurons (PF / Granular)
    for (int i = 0; i < 10; i++) {
      neurons.add(NeuronModel.initial(
        id: 'pf_$i',
        cellType: 'GC',
      ));
    }

    // 2. Basket Cells (BC)
    for (int i = 0; i < 5; i++) {
      neurons.add(NeuronModel.initial(
        id: 'bc_$i',
        cellType: 'BC',
      ));
    }

    // 3. Purkinje Cells (PC)
    neurons.add(NeuronModel.initial(id: 'pc_1', cellType: 'PC'));
    neurons.add(NeuronModel.initial(id: 'pc_2', cellType: 'PC'));

    // 4. Stellate Cell (SC)
    neurons.add(NeuronModel.initial(id: 'sc_1', cellType: 'SC'));

    // 5. DCN Cells
    neurons.add(NeuronModel.initial(id: 'dcn_open', cellType: 'DCN'));
    neurons.add(NeuronModel.initial(id: 'dcn_close', cellType: 'DCN'));

    // 6. Connect PFs to BC, PC, and SC
    for (int i = 0; i < 10; i++) {
      synapses.add(SynapseModel(
        id: 'pf_$i->pc_1',
        fromNeuronId: 'pf_$i',
        toNeuronId: 'pc_1',
        weight: 0.5,
        isInhibitory: false,
      ));
      synapses.add(SynapseModel(
        id: 'pf_$i->pc_2',
        fromNeuronId: 'pf_$i',
        toNeuronId: 'pc_2',
        weight: 0.5,
        isInhibitory: false,
      ));
      
      synapses.add(SynapseModel(
        id: 'pf_$i->sc_1',
        fromNeuronId: 'pf_$i',
        toNeuronId: 'sc_1',
        weight: 0.2,
        isInhibitory: false,
      ));
      
      synapses.add(SynapseModel(
        id: 'pf_$i->bc_${(i / 2).floor()}',
        fromNeuronId: 'pf_$i',
        toNeuronId: 'bc_${(i / 2).floor()}',
        weight: 0.3,
        isInhibitory: false,
      ));
    }

    // 7. Inhibitory Synapses
    for (int i = 0; i < 5; i++) {
      synapses.add(SynapseModel(
        id: 'bc_$i->pc_1',
        fromNeuronId: 'bc_$i',
        toNeuronId: 'pc_1',
        weight: -1.0,
        isInhibitory: true,
      ));
      synapses.add(SynapseModel(
        id: 'bc_$i->pc_2',
        fromNeuronId: 'bc_$i',
        toNeuronId: 'pc_2',
        weight: -1.0,
        isInhibitory: true,
      ));
    }

    synapses.add(const SynapseModel(
      id: 'pc_1->dcn_open',
      fromNeuronId: 'pc_1',
      toNeuronId: 'dcn_open',
      weight: -2.0,
      isInhibitory: true,
    ));
    synapses.add(const SynapseModel(
      id: 'pc_2->dcn_close',
      fromNeuronId: 'pc_2',
      toNeuronId: 'dcn_close',
      weight: -2.0,
      isInhibitory: true,
    ));

    return SimulationState(neurons: neurons, synapses: synapses);
  }
}
