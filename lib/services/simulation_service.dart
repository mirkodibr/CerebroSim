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
}
