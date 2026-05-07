import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cerebrosim/providers/simulation_provider.dart';
import 'package:cerebrosim/models/simulation_state.dart';
import 'package:flutter/scheduler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ColdSimState initial isThrottled is false', () {
    const state = ColdSimState();
    expect(state.isThrottled, isFalse);
  });

  test('ColdSimState copyWith isThrottled', () {
    const state = ColdSimState();
    final throttled = state.copyWith(isThrottled: true);
    expect(throttled.isThrottled, isTrue);
  });

  // Note: Testing the actual throttling logic in SimulationController 
  // requires inducing >12ms frame times, which is difficult in a unit test
  // without a mockable engine (P1.6). 
}
