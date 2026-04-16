import 'dart:math' as math;
import '../models/neuron_model.dart';
import '../models/synapse_model.dart';
import '../models/simulation_state.dart';
import '../models/network_config.dart';

/// Helper class for setting up various neural network configurations.
/// 
/// It centralizes the logic for creating the initial neurons and their 
/// synaptic connections for specific cerebellar tasks.
class NetworkInitializer {
  /// Creates a mock cerebellar network based on the provided [config].
  /// 
  /// The network utilizes probabilistic wiring to ensure realistic sparsity:
  /// - Each Granule Cell (GC) connects to exactly 70% of available PCs and BCs.
  /// - Basket Cells (BC) and Purkinje Cells (PC) provide standard inhibitory motifs.
  /// 
  /// Synaptic setup:
  /// - GC -> PC, BC, SC (Excitatory, with 2-5 frame axonal delays)
  /// - BC -> PC (Inhibitory, instantaneous)
  /// - PC -> DCN (Inhibitory, instantaneous)
  static SimulationState createRLMockNetwork({NetworkConfig? config}) {
    final cfg = config ?? NetworkConfig.defaultConfig();
    final neurons = <String, NeuronModel>{};
    final synapses = <SynapseModel>[];
    final random = math.Random();

    // 1. Parallel Fiber neurons (PF / Granular)
    for (int i = 0; i < cfg.gcCount; i++) {
      final id = 'pf_$i';
      neurons[id] = NeuronModel.initial(id: id, cellType: 'GC');
    }

    // 2. Basket Cells (BC)
    for (int i = 0; i < cfg.bcCount; i++) {
      final id = 'bc_$i';
      neurons[id] = NeuronModel.initial(id: id, cellType: 'BC');
    }

    // 3. Purkinje Cells (PC)
    for (int i = 0; i < cfg.pcCount; i++) {
      final id = 'pc_$i';
      neurons[id] = NeuronModel.initial(id: id, cellType: 'PC');
    }

    // 4. Stellate Cells (SC)
    for (int i = 0; i < cfg.scCount; i++) {
      final id = 'sc_$i';
      neurons[id] = NeuronModel.initial(id: id, cellType: 'SC');
    }

    // 5. DCN Cells
    // We maintain 'dcn_open' and 'dcn_close' naming for task compatibility if count is 2.
    // For ArmReaching, we expect x_pos, x_neg, y_pos, y_neg (count 4).
    if (cfg.dcnCount == 2) {
      neurons['dcn_open'] = NeuronModel.initial(id: 'dcn_open', cellType: 'DCN');
      neurons['dcn_close'] = NeuronModel.initial(id: 'dcn_close', cellType: 'DCN');
    } else if (cfg.dcnCount == 4) {
      neurons['x_pos'] = NeuronModel.initial(id: 'x_pos', cellType: 'DCN');
      neurons['x_neg'] = NeuronModel.initial(id: 'x_neg', cellType: 'DCN');
      neurons['y_pos'] = NeuronModel.initial(id: 'y_pos', cellType: 'DCN');
      neurons['y_neg'] = NeuronModel.initial(id: 'y_neg', cellType: 'DCN');
    } else {
      for (int i = 0; i < cfg.dcnCount; i++) {
        final id = 'dcn_$i';
        neurons[id] = NeuronModel.initial(id: id, cellType: 'DCN');
      }
    }

    // 6. Climbing Fiber (CF) - Error Signal
    neurons['cf_0'] = NeuronModel.initial(id: 'cf_0', cellType: 'CF');

    // 7. Probabilistic GC Connections (Excitatory)
    // Connect each GC to 70% of PCs and BCs.
    final pcIds = neurons.values.where((n) => n.cellType == 'PC').map((n) => n.id).toList();
    final bcIds = neurons.values.where((n) => n.cellType == 'BC').map((n) => n.id).toList();
    final scIds = neurons.values.where((n) => n.cellType == 'SC').map((n) => n.id).toList();

    for (int i = 0; i < cfg.gcCount; i++) {
      final gcId = 'pf_$i';
      final pfDelay = 2 + random.nextInt(4);

      // GC -> PC (Probabilistic 70%)
      _connectProbabilistic(gcId, pcIds, 0.7, synapses, random, pfDelay, 0.5, false);
      
      // GC -> BC (Probabilistic 70%)
      _connectProbabilistic(gcId, bcIds, 0.7, synapses, random, pfDelay, 0.3, false);

      // GC -> SC (Probabilistic 70%)
      _connectProbabilistic(gcId, scIds, 0.7, synapses, random, pfDelay, 0.2, false);
    }

    // 7. Inhibitory Motif: BC -> PC
    // Each BC inhibits a subset of PCs (probabilistic 60%)
    for (final bcId in bcIds) {
      _connectProbabilistic(bcId, pcIds, 0.6, synapses, random, 0, -1.0, true);
    }

    // 8. Inhibitory Motif: PC -> DCN
    // Purkinje cells are the sole output of the cortex, inhibiting DCN.
    final dcnIds = neurons.values.where((n) => n.cellType == 'DCN').map((n) => n.id).toList();
    for (final pcId in pcIds) {
      // Connect each PC to at least one DCN, or probabilistic 80% if many
      _connectProbabilistic(pcId, dcnIds, 0.8, synapses, random, 0, -2.0, true);
    }

    return SimulationState(neurons: neurons, synapses: synapses).rebuildIndex();
  }

  /// Internal helper to create synapses between a source and a list of targets with a given probability.
  static void _connectProbabilistic(
    String fromId, 
    List<String> targetIds, 
    double probability, 
    List<SynapseModel> synapses, 
    math.Random random,
    int delay,
    double weight,
    bool isInhibitory
  ) {
    if (targetIds.isEmpty) return;
    
    // Shuffle targets to ensure even distribution when probability is applied
    final targets = List<String>.from(targetIds)..shuffle(random);
    final count = (targets.length * probability).ceil().clamp(1, targets.length);

    for (int i = 0; i < count; i++) {
      final toId = targets[i];
      synapses.add(SynapseModel(
        id: '$fromId->$toId',
        fromNeuronId: fromId,
        toNeuronId: toId,
        weight: weight,
        isInhibitory: isInhibitory,
        axonalDelay: delay,
      ));
    }
  }
}
