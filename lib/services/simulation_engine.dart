import 'package:meta/meta.dart';
import '../models/simulation_state.dart';
import '../models/neuron_model.dart';
import '../models/synapse_model.dart';
import '../models/environment.dart';
import '../models/simulation_constants.dart';

/// The core computational engine of the cerebellar simulation.
/// 
/// This class implements the mathematical models for:
/// - **Neuron Dynamics:** Leaky Integrate-and-Fire (LIF) equations.
/// - **Synaptic Propagation:** Weighted summation of pre-synaptic activity.
/// - **Synaptic Plasticity:** Temporal Difference (TD) learning using 
///   eligibility traces.
/// - **Temporal Memory:** Eligibility trace updates for bridging time gaps.
class SimulationEngine {
  /// Returns a [SimulationState] initialized with default neurons and synapses.
  SimulationState initialState() {
    return SimulationState.initial();
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
  SimulationState tick(SimulationState current, EnvironmentStep env, double dt) {
    // Step 1: compute input currents
    final Map<String, double> inputCurrents = {};
    
    // CF receives env.punishment (representing the error signal)
    // GC receives context (stateVector[0])
    for (final n in current.neurons) {
      if (n.cellType == 'CF') {
        inputCurrents[n.id] = env.punishment;
      } else if (n.cellType == 'GC') {
        inputCurrents[n.id] = env.stateVector.isNotEmpty ? env.stateVector[0] : 0.0;
      } else {
        inputCurrents[n.id] = 0.0;
      }
    }

    // Weighted sum from synapses: propagate pre-synaptic activity to post-synaptic targets.
    for (final s in current.synapses) {
      final preNeuron = current.neurons.firstWhere((n) => n.id == s.fromNeuronId);
      final currentIn = inputCurrents[s.toNeuronId] ?? 0.0;
      // Use membranePotential from PREVIOUS state for synaptic propagation
      inputCurrents[s.toNeuronId] = currentIn + (s.weight * preNeuron.membranePotential);
    }

    // Apply baseline tonic firing to DCN neurons to represent spontaneous activity.
    for (final n in current.neurons) {
      if (n.cellType == 'DCN') {
        inputCurrents[n.id] = (inputCurrents[n.id] ?? 0.0) + 0.5;
      }
    }

    // Step 2: run lifUpdate and eligibilityUpdate for each neuron.
    final List<NeuronModel> nextNeurons = current.neurons.map((n) {
      final input = inputCurrents[n.id] ?? 0.0;
      double newPotential = lifUpdate(n, input);
      bool isFiring = newPotential >= n.threshold;
      
      // If firing, reset potential back to resting level.
      if (isFiring) {
        newPotential = n.restingPotential;
      }

      // Update eligibility trace based on current firing activity.
      final double activity = isFiring ? 1.0 : 0.0;
      final newTrace = eligibilityUpdate(n.eligibilityTrace, activity, n.decayRate);

      return n.copyWith(
        membranePotential: newPotential,
        isFiring: isFiring,
        eligibilityTrace: newTrace,
      );
    }).toList();

    // Step 3: compute tdError
    // In this cerebellar context, reward is defined as (1.0 - punishment).
    // The DCN neuron acts as the state-value estimator.
    final oldDcn = current.neurons.firstWhere((n) => n.cellType == 'DCN', orElse: () => current.neurons.first);
    final nextDcn = nextNeurons.firstWhere((n) => n.id == oldDcn.id);
    
    final td = tdError(1.0 - env.punishment, nextDcn.membranePotential, oldDcn.membranePotential);

    // Step 4: call updateWeights to adjust synaptic strengths based on learning.
    final List<SynapseModel> nextSynapses = updateWeights(
      current.synapses,
      nextNeurons, // Use updated neurons for eligibility trace
      td,
      SimulationConstants.kDefaultLearningRate,
    );

    // Step 5: handle episode logic and counter increments.
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

  /// Calculates the next membrane potential using a Leaky Integrate-and-Fire model.
  /// 
  /// The model takes the current potential, adds the [inputCurrent], 
  /// and applies a [decayRate] representing the leakage of the cell.
  @visibleForTesting
  double lifUpdate(NeuronModel n, double inputCurrent) {
    return (n.membranePotential + inputCurrent) * (1 - n.decayRate);
  }

  /// Calculates the Temporal Difference (TD) error for reinforcement learning.
  /// 
  /// [reward] is the immediate environmental feedback.
  /// [vNext] is the estimated value of the next state (new DCN potential).
  /// [vCurrent] is the estimated value of the current state (old DCN potential).
  /// [gamma] is the discount factor for future rewards.
  @visibleForTesting
  double tdError(double reward, double vNext, double vCurrent, {double gamma = 0.95}) {
    return reward + gamma * vNext - vCurrent;
  }

  /// Updates synaptic weights according to the TD-learning rule and eligibility traces.
  /// 
  /// Each [synapse] is adjusted by: `deltaW = sign * learningRate * tdError * eligibilityTrace`.
  /// The weights are clamped between -2.0 and 2.0 to maintain numerical stability.
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

  /// Updates a neuron's eligibility trace, representing a temporal memory of activity.
  /// 
  /// The [currentTrace] decays by [decayRate] and is incremented by [preSynapticActivity].
  @visibleForTesting
  double eligibilityUpdate(double currentTrace, double preSynapticActivity, double decayRate) {
    return currentTrace * (1 - decayRate) + preSynapticActivity;
  }
}
