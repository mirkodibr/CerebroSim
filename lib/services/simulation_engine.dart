import 'package:meta/meta.dart';
import '../models/simulation_state.dart';
import '../models/neuron_model.dart';
import '../models/synapse_model.dart';
import '../models/environment.dart';
import '../models/simulation_constants.dart';

class SimulationEngine {
  SimulationState initialState() {
    return SimulationState.initial();
  }

  SimulationState tick(SimulationState current, EnvironmentStep env, double dt) {
    // Step 1: compute input currents
    final Map<String, double> inputCurrents = {};
    
    // CF receives env.punishment
    for (final n in current.neurons) {
      if (n.cellType == 'CF') {
        inputCurrents[n.id] = env.punishment;
      } else if (n.cellType == 'GC') {
        inputCurrents[n.id] = env.stateVector.isNotEmpty ? env.stateVector[0] : 0.0;
      } else {
        inputCurrents[n.id] = 0.0;
      }
    }

    // Weighted sum from synapses
    for (final s in current.synapses) {
      final preNeuron = current.neurons.firstWhere((n) => n.id == s.fromNeuronId);
      final currentIn = inputCurrents[s.toNeuronId] ?? 0.0;
      // Use membranePotential from PREVIOUS state for synaptic propagation
      inputCurrents[s.toNeuronId] = currentIn + (s.weight * preNeuron.membranePotential);
    }

    // DCN baseline
    for (final n in current.neurons) {
      if (n.cellType == 'DCN') {
        inputCurrents[n.id] = (inputCurrents[n.id] ?? 0.0) + 0.5;
      }
    }

    // Step 2: run lifUpdate and eligibilityUpdate
    final List<NeuronModel> nextNeurons = current.neurons.map((n) {
      final input = inputCurrents[n.id] ?? 0.0;
      double newPotential = lifUpdate(n, input);
      bool isFiring = newPotential >= n.threshold;
      
      if (isFiring) {
        newPotential = n.restingPotential;
      }

      // Update eligibility trace
      // Activity is 1.0 if firing, 0.0 otherwise
      final double activity = isFiring ? 1.0 : 0.0;
      final newTrace = eligibilityUpdate(n.eligibilityTrace, activity, n.decayRate);

      return n.copyWith(
        membranePotential: newPotential,
        isFiring: isFiring,
        eligibilityTrace: newTrace,
      );
    }).toList();

    // Step 3: compute tdError
    // Reward = 1.0 - env.punishment
    // vNext = DCN's new potential
    // vCurrent = DCN's old potential
    final oldDcn = current.neurons.firstWhere((n) => n.cellType == 'DCN', orElse: () => current.neurons.first);
    final nextDcn = nextNeurons.firstWhere((n) => n.id == oldDcn.id);
    
    final td = tdError(1.0 - env.punishment, nextDcn.membranePotential, oldDcn.membranePotential);

    // Step 4: call updateWeights
    final List<SynapseModel> nextSynapses = updateWeights(
      current.synapses,
      nextNeurons, // Use updated neurons for eligibility trace
      td,
      SimulationConstants.kDefaultLearningRate,
    );

    // Step 5: handle episode logic
    int nextStep = current.episodeStep + 1;
    int nextEpisodeCount = current.episodeCount;
    if (env.isEpisodeEnd) {
      nextStep = 0;
      nextEpisodeCount++;
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
    List<NeuronModel> neurons,
    double tdError,
    double learningRate,
  ) {
    return synapses.map((synapse) {
      final preNeuron = neurons.firstWhere((n) => n.id == synapse.fromNeuronId);
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
