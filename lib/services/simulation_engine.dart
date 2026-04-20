import 'package:flutter/foundation.dart';
import '../models/simulation_state.dart';
import '../models/neuron_model.dart';
import '../models/synapse_model.dart';
import '../models/environment.dart';

import '../models/network_config.dart';
import 'network_initializer.dart';

/// The core computational engine of the cerebellar simulation.
/// 
/// This class implements the mathematical models for:
/// - **Neuron Dynamics:** Leaky Integrate-and-Fire (LIF) equations.
/// - **Synaptic Propagation:** Weighted summation of pre-synaptic activity.
/// - **Synaptic Plasticity:** Temporal Difference (TD) learning using 
///   eligibility traces.
/// - **Temporal Memory:** Eligibility trace updates for bridging time gaps.
class SimulationEngine {
  static const int _maxDelay = 10; // max axonal delay in ticks

  /// A temporal ring buffer to schedule future synaptic currents based on axonal delays.
  /// Key 1: Target tick (episodeStep).
  /// Key 2: Target neuron ID.
  /// Value: Accumulated current to be applied at that tick.
  final Map<int, Map<String, double>> _potentialBuffer = {};

  /// Returns a [SimulationState] initialized based on the provided [config].
  SimulationState initialState({NetworkConfig? config}) {
    return NetworkInitializer.createRLMockNetwork(config: config);
  }

  /// Clears the temporal ring buffer. 
  /// Should be called during simulation resets or when loading new configurations.
  void clearBuffer() {
    assert(() {
      if (_potentialBuffer.isNotEmpty) {
        debugPrint('SimulationEngine: clearing ${_potentialBuffer.length} '
          'stale buffer entries');
      }
      return true;
    }());
    _potentialBuffer.clear();
  }

  /// Advances the simulation by a single time step [dt].
  /// 
  /// The [tick] process follows these stages:
  /// 1. **Compute Input Currents:** Aggregate sensory input and synaptic currents.
  /// 2. **Update Neurons:** Apply [lifUpdate] to membrane potentials and 
  ///    [eligibilityUpdate] to traces.
  /// 3. **Calculate Error:** Determine the [tdError] based on environmental 
  ///    reward and DCN activity.
  /// 4. **Apply Plasticity:** Use [updateWeights] to modify synapses based on
  ///    the TD error.
  /// 5. **Update State:** Manage episode counting and step tracking.
  SimulationState tick(
    SimulationState current,
    EnvironmentStep env,
    double dt, {
    required double learningRate,
    required double gamma,
    required double dcnBaseline,
  }) {
    // Step 1: compute input currents
    final Map<String, double> inputCurrents = {};
    
    // CF receives env.punishment (representing the error signal)
    // GC receives context (stateVector[0])
    for (final n in current.neurons.values) {
      if (n.cellType == 'CF') {
        inputCurrents[n.id] = env.punishment;
      } else if (n.cellType == 'GC') {
        inputCurrents[n.id] = env.stateVector.isNotEmpty ? env.stateVector[0] : 0.0;
      } else {
        inputCurrents[n.id] = 0.0;
      }
    }

    // Pull scheduled currents from the buffer for the current tick.
    final scheduledForNow = _potentialBuffer.remove(current.episodeStep);
    if (scheduledForNow != null) {
      for (final entry in scheduledForNow.entries) {
        inputCurrents[entry.key] = (inputCurrents[entry.key] ?? 0.0) + entry.value;
      }
    }

    // Prune stale entries older than maxDelay ticks behind current step
    final staleKeys = _potentialBuffer.keys
      .where((k) => k < current.episodeStep - _maxDelay)
      .toList();
    for (final k in staleKeys) {
      _potentialBuffer.remove(k);
    }

    // Optimized propagation: Iterate over neurons. If they have activity (membranePotential > 0),
    // propagate to downstream targets via the preSynapticIndex.
    for (final n in current.neurons.values) {
      if (n.membranePotential > 0) {
        final downstreamSynapses = current.preSynapticIndex[n.id];
        if (downstreamSynapses != null) {
          for (final s in downstreamSynapses) {
            final targetTick = current.episodeStep + s.axonalDelay;
            final currentIn = s.weight * n.membranePotential;
            
            if (s.axonalDelay == 0) {
              // Instantaneous propagation
              inputCurrents[s.toNeuronId] = (inputCurrents[s.toNeuronId] ?? 0.0) + currentIn;
            } else {
              // Schedule for future tick
              final tickBuffer = _potentialBuffer.putIfAbsent(targetTick, () => {});
              tickBuffer[s.toNeuronId] = (tickBuffer[s.toNeuronId] ?? 0.0) + currentIn;
            }
          }
        }
      }
    }

    // Apply baseline tonic firing to DCN neurons to represent spontaneous activity.
    for (final n in current.neurons.values) {
      if (n.cellType == 'DCN') {
        inputCurrents[n.id] = (inputCurrents[n.id] ?? 0.0) + dcnBaseline;
      }
    }

    // Step 2: run lifUpdate and eligibilityUpdate for each neuron.
    final Map<String, NeuronModel> nextNeurons = current.neurons.map((id, n) {
      final input = inputCurrents[id] ?? 0.0;
      double newPotential = lifUpdate(n, input);
      bool isFiring = newPotential >= n.threshold;
      
      // If firing, reset potential back to resting level.
      if (isFiring) {
        newPotential = n.restingPotential;
      }

      // Update eligibility trace based on current firing activity.
      final double activity = isFiring ? 1.0 : 0.0;
      final newTrace = eligibilityUpdate(n.eligibilityTrace, activity, n.decayRate);

      return MapEntry(id, n.copyWith(
        membranePotential: newPotential,
        isFiring: isFiring,
        eligibilityTrace: newTrace,
      ));
    });

    // Step 3: compute tdError
    // In this cerebellar context, reward is defined as (1.0 - punishment).
    // The DCN neuron acts as the state-value estimator.
    // For tasks with multiple DCNs (like ArmReaching), we use the average 
    // membrane potential to estimate the state value.
    final dcns = current.neurons.values.where((n) => n.cellType == 'DCN').toList();
    
    double oldV = 0.0;
    double nextV = 0.0;

    if (dcns.isNotEmpty) {
      for (final dcn in dcns) {
        oldV += dcn.membranePotential;
        nextV += nextNeurons[dcn.id]?.membranePotential ?? 0.0;
      }
      oldV /= dcns.length;
      nextV /= dcns.length;
    } else {
      // Fallback
      oldV = current.neurons.values.first.membranePotential;
      nextV = nextNeurons.values.first.membranePotential;
    }
    
    final td = tdError(1.0 - env.punishment, nextV, oldV, gamma: gamma);

    // Step 4: call updateWeights to adjust synaptic strengths based on learning.
    final List<SynapseModel> nextSynapses = updateWeights(
      current.synapses,
      nextNeurons, 
      td,
      learningRate: learningRate,
    );

    // Step 5: handle episode logic and counter increments.
    int nextStep = current.episodeStep + 1;
    int nextEpisodeCount = current.episodeCount;
    if (env.isEpisodeEnd) {
      nextStep = 0;
      nextEpisodeCount++;
      // Biologically, axonal delays are usually cleared at the end of an episode/trial
      // to prevent "leakage" into the next one.
      clearBuffer();
    }

    return current.copyWith(
      neurons: nextNeurons,
      synapses: nextSynapses,
      tdError: td,
      climbingFiberSignal: env.punishment,
      episodeStep: nextStep,
      episodeCount: nextEpisodeCount,
    );
  }

  /// Calculates the next membrane potential using a Leaky Integrate-and-Fire model.
  @visibleForTesting
  double lifUpdate(NeuronModel n, double inputCurrent) {
    return (n.membranePotential + inputCurrent) * (1 - n.decayRate);
  }

  /// Calculates the Temporal Difference (TD) error for reinforcement learning.
  @visibleForTesting
  double tdError(double reward, double vNext, double vCurrent, {double gamma = 0.95}) {
    return reward + gamma * vNext - vCurrent;
  }

  /// Updates synaptic weights according to the TD-learning rule and eligibility traces.
  @visibleForTesting
  List<SynapseModel> updateWeights(
    List<SynapseModel> synapses,
    Map<String, NeuronModel> neurons,
    double tdError, {
    required double learningRate,
  }) {
    return synapses.map((synapse) {
      final preNeuron = neurons[synapse.fromNeuronId];
      if (preNeuron == null) return synapse;

      final sign = synapse.isInhibitory ? -1.0 : 1.0;
      final deltaW = sign * learningRate * tdError * preNeuron.eligibilityTrace;
      final newWeight = (synapse.weight + deltaW).clamp(-2.0, 2.0);
      return synapse.copyWith(weight: newWeight);
    }).toList();
  }

  /// Updates a neuron's eligibility trace, representing a temporal memory of activity.
  @visibleForTesting
  double eligibilityUpdate(double currentTrace, double preSynapticActivity, double decayRate) {
    return currentTrace * (1 - decayRate) + preSynapticActivity;
  }
}
