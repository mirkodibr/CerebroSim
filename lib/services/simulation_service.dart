import '../models/neuron.dart';
import '../models/synapse.dart';
import '../models/simulation_state.dart';

class SimulationService {
  /// Processes a single discrete time step (tick) of the simulation.
  /// 
  /// Logic:
  /// 1. Identify which neurons spike (potential >= threshold).
  /// 2. For each spiking neuron:
  ///    - Reset its potential to 0.0.
  ///    - Propagate its 'signal' (using synaptic weights) to downstream neurons.
  /// 3. Update all neurons with their new potentials.
  SimulationState calculateNextState(SimulationState currentState) {
    final Map<String, double> potentialDeltas = {};
    final Set<String> spikingNeurons = {};

    // 1. Identify spiking neurons and calculate propagation
    for (final neuron in currentState.neurons) {
      if (neuron.currentPotential >= neuron.threshold && neuron.threshold > 0) {
        spikingNeurons.add(neuron.id);
        
        // Find outgoing synapses for this spiking neuron
        final outgoingSynapses = currentState.synapses.where((s) => s.sourceId == neuron.id);
        
        for (final synapse in outgoingSynapses) {
          final currentDelta = potentialDeltas[synapse.targetId] ?? 0.0;
          potentialDeltas[synapse.targetId] = currentDelta + synapse.weight;
        }
      }
    }

    // 2. Build the new list of neurons with updated potentials
    final List<Neuron> nextNeurons = currentState.neurons.map((neuron) {
      double nextPotential;
      
      if (spikingNeurons.contains(neuron.id)) {
        // Spiked: reset to baseline (0.0) and then add any incoming potentials from other spikes
        nextPotential = potentialDeltas[neuron.id] ?? 0.0;
      } else {
        // Did not spike: keep current potential and add incoming potentials
        nextPotential = neuron.currentPotential + (potentialDeltas[neuron.id] ?? 0.0);
      }

      return neuron.copyWith(currentPotential: nextPotential);
    }).toList();

    return currentState.copyWith(neurons: nextNeurons);
  }

  /// Implements the Climbing Fiber Algorithm (error-correction).
  /// 
  /// Logic:
  /// 1. Compare the Purkinje neuron's spiking state with the [targetSignal].
  /// 2. If there's an error (e.g., target says it should spike, but it didn't, or vice-versa),
  ///    adjust the weights of all active synapses connecting to that Purkinje neuron.
  /// 3. In the Marr-Albus-Ito theory, a climbing fiber signal typically triggers
  ///    Long-Term Depression (LTD) when a parallel fiber is active simultaneously.
  SimulationState adjustWeights(
    SimulationState currentState, {
    required String purkinjeId,
    required bool targetSignal,
  }) {
    final purkinjeNeuron = currentState.neurons.firstWhere((n) => n.id == purkinjeId);
    final isSpiking = purkinjeNeuron.currentPotential >= purkinjeNeuron.threshold;

    // Simplified error logic:
    // If target is true (should spike) but isSpiking is false -> Increase weights of active inputs
    // If target is false (should not spike) but isSpiking is true -> Decrease weights of active inputs (LTD)
    
    if (isSpiking == targetSignal) {
      return currentState; // No error, no adjustment
    }

    final double adjustmentFactor = targetSignal ? 1.0 : -1.0;

    final List<Synapse> nextSynapses = currentState.synapses.map((synapse) {
      if (synapse.targetId == purkinjeId) {
        // Find the source neuron to see if it was active (spiked)
        final sourceNeuron = currentState.neurons.firstWhere((n) => n.id == synapse.sourceId);
        final wasSourceActive = sourceNeuron.currentPotential >= sourceNeuron.threshold;

        if (wasSourceActive) {
          // Adjust weight based on learning rate and direction of error
          final newWeight = synapse.weight + (synapse.learningRate * adjustmentFactor);
          // Weights usually don't go below 0 in simple models
          return synapse.copyWith(weight: newWeight < 0 ? 0.0 : newWeight);
        }
      }
      return synapse;
    }).toList();

    return currentState.copyWith(synapses: nextSynapses);
  }
}
