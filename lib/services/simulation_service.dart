import '../models/neuron.dart';
import '../models/synapse.dart';
import '../models/simulation_state.dart';

class SimulationService {
  /// Processes a single discrete time step (tick) of the simulation.
  /// 
  /// Updates for Continuous-Time RL:
  /// 1. LIF Dynamics: Non-spiking neurons decay their potential.
  /// 2. Eligibility Traces: Synapse traces decay and are reinforced by presynaptic spikes.
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

    // 2. Update eligibility traces (decay factor 0.95 + reinforce if source spiked)
    final List<Synapse> nextSynapses = currentState.synapses.map((synapse) {
      double newTrace = synapse.eligibilityTrace * 0.95;
      if (spikingNeurons.contains(synapse.sourceId)) {
        newTrace += 1.0;
      }
      return synapse.copyWith(eligibilityTrace: newTrace);
    }).toList();

    // 3. Build the new list of neurons with LIF dynamics
    final List<Neuron> nextNeurons = currentState.neurons.map((neuron) {
      double nextPotential;
      
      if (spikingNeurons.contains(neuron.id)) {
        // Spiked: reset to baseline (0.0) and then add any incoming potentials
        nextPotential = potentialDeltas[neuron.id] ?? 0.0;
      } else {
        // LIF: Decay current potential then add incoming potentials
        final decayedPotential = neuron.currentPotential * (1.0 - neuron.decayRate);
        nextPotential = decayedPotential + (potentialDeltas[neuron.id] ?? 0.0);
      }

      return neuron.copyWith(currentPotential: nextPotential);
    }).toList();

    return currentState.copyWith(
      neurons: nextNeurons,
      synapses: nextSynapses,
    );
  }

  /// Implements the Actor-Critic Learning Rule (Continuous-Time RL).
  /// 
  /// Logic:
  /// 1. Calculate predicted punishment from Stellate Cells (Critic).
  /// 2. Calculate TD Error.
  /// 3. Update weights of synapses with active eligibility traces.
  SimulationState adjustWeightsRL(
    SimulationState currentState, {
    required double climbingFiberPunishment,
  }) {
    // 1. Calculate predictedPunishment from all 'SC' neurons
    double predictedPunishment = 0.0;
    for (final neuron in currentState.neurons) {
      if (neuron.type == 'SC') {
        predictedPunishment += neuron.currentPotential;
      }
    }

    // 2. Calculate tdError
    final tdError = climbingFiberPunishment - predictedPunishment;

    // 3. Update weights based on traces and target type
    final List<Synapse> nextSynapses = currentState.synapses.map((synapse) {
      if (synapse.eligibilityTrace < 0.01) {
        return synapse;
      }

      double newWeight = synapse.weight;
      if (synapse.targetType == 'SC') {
        // Critic update: reinforce value prediction
        newWeight += synapse.learningRate * tdError * synapse.eligibilityTrace;
      } else if (synapse.targetType == 'PC') {
        // Actor update: LTD-like response to punishment
        newWeight -= synapse.learningRate * tdError * synapse.eligibilityTrace;
      }

      // Clamp weights between 0.0 and 1.0
      newWeight = newWeight.clamp(0.0, 1.0);
      
      return synapse.copyWith(weight: newWeight);
    }).toList();

    return currentState.copyWith(synapses: nextSynapses);
  }

  /// Returns the motor action executed by the DCN (Deep Cerebellar Nuclei).
  /// 
  /// Logic:
  /// 1. Filter for 'DCN' type neurons.
  /// 2. Find the one with the highest currentPotential.
  /// 3. Return its actionGroup string.
  /// 4. Returns 'none' if no DCN neurons exist or all potentials are 0.
  String getExecutedAction(SimulationState currentState) {
    final dcnNeurons = currentState.neurons.where((n) => n.type == 'DCN').toList();
    
    if (dcnNeurons.isEmpty) return 'none';

    Neuron? winner;
    double maxPotential = 0.0;

    for (final neuron in dcnNeurons) {
      if (neuron.currentPotential > maxPotential) {
        maxPotential = neuron.currentPotential;
        winner = neuron;
      }
    }

    return winner?.actionGroup ?? 'none';
  }
}
