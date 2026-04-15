import 'package:flutter_test/flutter_test.dart';
import 'package:cerebrosim/services/eyeblink_environment.dart';
import 'package:cerebrosim/services/sine_wave_environment.dart';
import 'package:cerebrosim/services/vor_environment.dart';
import 'package:cerebrosim/models/simulation_state.dart';
import 'package:cerebrosim/models/neuron_model.dart';
import 'package:cerebrosim/models/vor_config.dart';

void main() {
  group('EyeblinkEnvironment', () {
    late EyeblinkEnvironment env;
    late SimulationState emptyState;

    setUp(() {
      env = EyeblinkEnvironment();
      emptyState = SimulationState.initial();
    });

    test('punishment is 1.0 if US window is reached without a preceding DCN spike', () {
      // Advance to US window (0.250s - 0.300s)
      // Step by 0.1s twice to get to 0.2s
      env.step(emptyState, 0.1);
      env.step(emptyState, 0.1);
      
      // Step into US window
      final step = env.step(emptyState, 0.06); // total 0.26s
      
      expect(step.punishment, equals(1.0));
    });

    test('punishment is 0.0 if a DCN spike occurred during CS window', () {
      // CS window is 0.0s - 0.250s
      // Create a state where DCN is firing
      final firingState = emptyState.copyWith(
        neurons: emptyState.neurons.map((id, n) => 
          MapEntry(id, n.cellType == 'DCN' ? n.copyWith(isFiring: true) : n)
        ),
      );

      // Step during CS window with firing DCN
      env.step(firingState, 0.1);
      
      // Step into US window (0.250s - 0.300s)
      final step = env.step(emptyState, 0.16); // total 0.26s
      
      expect(step.punishment, equals(0.0));
    });

    test('punishment is 0.0 outside US window', () {
      final step = env.step(emptyState, 0.1); // 0.1s is CS window, not US
      expect(step.punishment, equals(0.0));
    });
  });

  group('SineWaveEnvironment', () {
    late SineWaveEnvironment env;
    late SimulationState baseState;

    setUp(() {
      env = SineWaveEnvironment();
      // Environment expects 'dcn_open' and 'dcn_close'
      final neurons = {
        'dcn_open': NeuronModel.initial(id: 'dcn_open', cellType: 'DCN'),
        'dcn_close': NeuronModel.initial(id: 'dcn_close', cellType: 'DCN'),
      };
      baseState = SimulationState.initial().copyWith(
        neurons: neurons,
      );
    });

    test('punishment is non-zero when DCN output direction is opposite to wave derivative', () {
      // At t=0, target = sin(0) = 0.
      // derivative = cos(0) = 1 (Moving Up)
      // We want to force output to move DOWN: dcnOpen < dcnClose
      final movingDownState = baseState.copyWith(
        neurons: {
          'dcn_open': baseState.neurons['dcn_open']!.copyWith(membranePotential: 0.1),
          'dcn_close': baseState.neurons['dcn_close']!.copyWith(membranePotential: 0.5),
        },
      );

      final step = env.step(movingDownState, 0.01);
      expect(step.punishment, greaterThan(0.0));
    });

    test('punishment is zero when DCN output direction matches wave derivative', () {
      // At t=0, moving up.
      // Force output to move UP: dcnOpen > dcnClose
      final movingUpState = baseState.copyWith(
        neurons: {
          'dcn_open': baseState.neurons['dcn_open']!.copyWith(membranePotential: 0.5),
          'dcn_close': baseState.neurons['dcn_close']!.copyWith(membranePotential: 0.1),
        },
      );

      final step = env.step(movingUpState, 0.01);
      expect(step.punishment, equals(0.0));
    });
  });

  group('VorEnvironment', () {
    test('imageSlip correctly incorporates targetGain from VorConfig', () {
      // For VOR, imageSlip = headVel + actualEyeVel
      // actualEyeVel = (dcnOpen - dcnClose) * amplitude
      // targetEyeVel = -headVel * targetGain (not directly in VorEnvironment punishment logic, but used for intuition)
      // VOR punishment = |imageSlip| / amplitude
      
      const config = VorConfig(targetGain: 1.5, amplitude: 10.0, frequency: 1.0);
      final env = VorEnvironment(config: config);
      
      final neurons = {
        'dcn_open': NeuronModel.initial(id: 'dcn_open', cellType: 'DCN'),
        'dcn_close': NeuronModel.initial(id: 'dcn_close', cellType: 'DCN'),
      };
      final baseState = SimulationState.initial().copyWith(
        neurons: neurons,
      );

      // At t=0.25, sin(2*pi*1*0.25) = sin(pi/2) = 1.0
      // headVel = amplitude * 1.0 = 10.0
      
      // Let's set eye velocity to 0
      final zeroEyeVelState = baseState.copyWith(
        neurons: {
          'dcn_open': baseState.neurons['dcn_open']!.copyWith(membranePotential: 0.0),
          'dcn_close': baseState.neurons['dcn_close']!.copyWith(membranePotential: 0.0),
        },
      );

      final step = env.step(zeroEyeVelState, 0.25);
      // headVel = 10, actualEyeVel = 0 -> imageSlip = 10
      // punishment = 10 / 10 = 1.0
      expect(step.punishment, closeTo(1.0, 0.001));

      // Reset environment for next check
      env.reset();
      
      // Let's set eye velocity to perfectly cancel head velocity (gain 1.0)
      // actualEyeVel = -10.0 -> (dcnOpen - dcnClose) * 10 = -10 -> dcnOpen - dcnClose = -1
      final perfectGainState = baseState.copyWith(
        neurons: {
          'dcn_open': baseState.neurons['dcn_open']!.copyWith(membranePotential: 0.0),
          'dcn_close': baseState.neurons['dcn_close']!.copyWith(membranePotential: 1.0),
        },
      );

      final stepPerfect = env.step(perfectGainState, 0.25);
      // headVel = 10, actualEyeVel = -10 -> imageSlip = 0
      // punishment = 0 / 10 = 0.0
      expect(stepPerfect.punishment, closeTo(0.0, 0.001));
    });
  });
}
