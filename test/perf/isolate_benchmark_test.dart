import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:cerebrosim/services/simulation_engine.dart';
import 'package:cerebrosim/services/simulation_isolate.dart';
import 'package:cerebrosim/providers/simulation_provider.dart';
import 'package:cerebrosim/models/simulation_state.dart';
import 'package:cerebrosim/models/environment.dart';
import 'package:cerebrosim/models/network_config.dart';

void main() {
  setUp(() {
    kUseIsolate = true;
  });

  group('Simulation Isolate Parity & Performance', () {
    test('Isolate path produces identical results to in-process path', () async {
      final engine = SimulationEngine();
      final config = NetworkConfig.defaultConfig();
      final initialState = engine.initialState(config: config);
      
      const env = EnvironmentStep(stateVector: [0.5], punishment: 0.1, isEpisodeEnd: false);
      const dt = 0.016;
      const lr = 0.01;
      const gamma = 0.95;
      const dcnBaseline = 0.5;

      // 1. In-process execution
      final inProcessResult = engine.tick(initialState, env, dt, learningRate: lr, gamma: gamma, dcnBaseline: dcnBaseline);

      // 2. Isolate execution
      final controller = SimulationIsolateController();
      await controller.spawn();
      controller.sendReset(config);
      
      final completer = Completer<HotSimState>();
      bool skipInitial = true;
      controller.stateStream.listen((hot) {
        if (skipInitial) {
          skipInitial = false;
          return;
        }
        if (!completer.isCompleted) completer.complete(hot);
      });

      controller.sendTick(env, dt, lr, gamma, dcnBaseline);
      final isolateResultHot = await completer.future.timeout(const Duration(seconds: 5));

      // 3. Compare
      expect(isolateResultHot.criticPrediction, closeTo(inProcessResult.criticPrediction, 0.000001));
      expect(isolateResultHot.tdError, closeTo(inProcessResult.tdError, 0.000001));
      
      // Compare a few neuron potentials
      for (final id in isolateResultHot.neurons.keys) {
        expect(isolateResultHot.neurons[id]!.membranePotential, 
               closeTo(inProcessResult.neurons[id]!.membranePotential, 0.000001));
      }

      await controller.dispose();
    });

    test('Benchmark: 200 ticks on a 200-neuron network', () async {
      final config = const NetworkConfig(
        gcCount: 150,
        bcCount: 20,
        pcCount: 20,
        scCount: 5,
        dcnCount: 4,
      ); // Total 199 + 1 CF = 200 neurons

      final controller = SimulationIsolateController();
      await controller.spawn();
      controller.sendReset(config);

      const env = EnvironmentStep(stateVector: [0.5], punishment: 0.1, isEpisodeEnd: false);
      const dt = 0.016;
      const lr = 0.01;
      const gamma = 0.95;
      const dcnBaseline = 0.5;

      final latencies = <int>[];
      final stopwatch = Stopwatch();

      final completer = Completer<void>();
      int count = 0;
      
      controller.stateStream.listen((_) {
        stopwatch.stop();
        latencies.add(stopwatch.elapsedMicroseconds);
        count++;
        if (count >= 200) {
          completer.complete();
        } else {
          stopwatch.reset();
          stopwatch.start();
          controller.sendTick(env, dt, lr, gamma, dcnBaseline);
        }
      });

      stopwatch.start();
      controller.sendTick(env, dt, lr, gamma, dcnBaseline);

      await completer.future.timeout(const Duration(seconds: 30));

      latencies.sort();
      final median = latencies[latencies.length ~/ 2];
      print('Isolate Benchmark (200 neurons):');
      print('  Median Tick Latency: ${median}µs');
      print('  Min Latency: ${latencies.first}µs');
      print('  Max Latency: ${latencies.last}µs');

      await controller.dispose();
    }, timeout: const Timeout(Duration(minutes: 1)));
  });
}
