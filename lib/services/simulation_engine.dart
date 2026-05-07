import 'package:flutter/foundation.dart';
import '../models/simulation_state.dart';
import '../models/neuron_model.dart';
import '../models/synapse_model.dart';
import '../models/environment.dart';

import '../models/network_config.dart';
import 'network_initializer.dart';

/// The core computational engine of the cerebellar simulation.
class SimulationEngine {
  static const int _maxDelay = 10; // max axonal delay in ticks
  static const int _bufferSize = _maxDelay + 1;

  /// A temporal ring buffer to schedule future synaptic currents based on axonal delays.
  /// This is implemented as a fixed-size list of maps to ensure O(1) access and 
  /// zero allocation overhead during the hot path.
  final List<Map<String, double>> _potentialBuffer = List.generate(
    _bufferSize, 
    (_) => {}, 
    growable: false
  );

  /// Returns a [SimulationState] initialized based on the provided [config].
  SimulationState initialState({NetworkConfig? config}) {
    return NetworkInitializer.createRLMockNetwork(config: config);
  }

  /// Returns the number of slots in the temporal ring buffer.
  /// Always equals [_maxDelay] + 1 (bounded by construction).
  @visibleForTesting
  int get bufferSize => _potentialBuffer.length;

  /// Clears all scheduled currents in the temporal ring buffer.
  void clearBuffer() {
    for (final map in _potentialBuffer) {
      map.clear();
    }
  }

  /// Advances the simulation by a single time step [dt].
  SimulationState tick(
    SimulationState current,
    EnvironmentStep env,
    double dt, {
    required double learningRate,
    required double gamma,
    required double dcnBaseline,
  }) {
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

    // Pull scheduled currents for the current tick from the ring buffer.
    final int currentIndex = current.episodeStep % _bufferSize;
    final scheduledForNow = _potentialBuffer[currentIndex];
    
    for (final entry in scheduledForNow.entries) {
      inputCurrents[entry.key] = (inputCurrents[entry.key] ?? 0.0) + entry.value;
    }
    
    // CRITICAL: Clear the buffer slot after consuming it so it's ready for future use
    scheduledForNow.clear();

    // Optimized propagation: Iterate over neurons with activity
    for (final n in current.neurons.values) {
      if (n.membranePotential > 0) {
        final downstreamSynapses = current.preSynapticIndex[n.id];
        if (downstreamSynapses != null) {
          for (final s in downstreamSynapses) {
            final targetTick = current.episodeStep + s.axonalDelay;
            final currentIn = s.weight * n.membranePotential;
            
            if (s.axonalDelay == 0) {
              inputCurrents[s.toNeuronId] = (inputCurrents[s.toNeuronId] ?? 0.0) + currentIn;
            } else {
              // Schedule for future tick using modulo indexing
              final int targetIndex = targetTick % _bufferSize;
              final targetMap = _potentialBuffer[targetIndex];
              targetMap[s.toNeuronId] = (targetMap[s.toNeuronId] ?? 0.0) + currentIn;
            }
          }
        }
      }
    }

    // Apply baseline tonic firing to DCN neurons
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
      
      if (isFiring) {
        newPotential = n.restingPotential;
      }

      final double activity = isFiring ? 1.0 : 0.0;
      final newTrace = eligibilityUpdate(n.eligibilityTrace, activity, n.decayRate);

      return MapEntry(id, n.copyWith(
        membranePotential: newPotential,
        isFiring: isFiring,
        eligibilityTrace: newTrace,
      ));
    });

    // Step 3: compute tdError
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
      oldV = current.neurons.values.first.membranePotential;
      nextV = nextNeurons.values.first.membranePotential;
    }
    
    final td = tdError(1.0 - env.punishment, nextV, oldV, gamma: gamma);

    // Step 4: Plasticity
    final List<SynapseModel> nextSynapses = updateWeights(
      current.synapses,
      nextNeurons, 
      td,
      learningRate: learningRate,
    );

    final Map<String, List<SynapseModel>> nextIndex = {};
    for (final s in nextSynapses) {
      nextIndex.putIfAbsent(s.fromNeuronId, () => []).add(s);
    }

    // Step 5: handle episode logic
    int nextStep = current.episodeStep + 1;
    int nextEpisodeCount = current.episodeCount;
    if (env.isEpisodeEnd) {
      nextStep = 0;
      nextEpisodeCount++;
      clearBuffer();
    }

    final double instantGain = env.stateVector.length >= 4 ? env.stateVector[2] : 0.0;
    final double newRollingGain = (0.95 * current.rollingGainRatio) + (0.05 * instantGain);

    return current.copyWith(
      neurons: nextNeurons,
      synapses: nextSynapses,
      preSynapticIndex: nextIndex,
      criticPrediction: nextV,
      tdError: td,
      climbingFiberSignal: env.punishment,
      rollingGainRatio: newRollingGain,
      episodeStep: nextStep,
      episodeCount: nextEpisodeCount,
    );
  }

  @visibleForTesting
  double lifUpdate(NeuronModel n, double inputCurrent) {
    return (n.membranePotential + inputCurrent) * (1 - n.decayRate);
  }

  @visibleForTesting
  double tdError(double reward, double vNext, double vCurrent, {double gamma = 0.95}) {
    return reward + gamma * vNext - vCurrent;
  }

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

  @visibleForTesting
  double eligibilityUpdate(double currentTrace, double preSynapticActivity, double decayRate) {
    return currentTrace * (1 - decayRate) + preSynapticActivity;
  }
}
