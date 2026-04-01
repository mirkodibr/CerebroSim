import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/simulation_constants.dart';

class LearningRateNotifier extends Notifier<double> {
  @override
  double build() => SimulationConstants.kDefaultLearningRate;

  set value(double v) => state = v;
}

final learningRateProvider = NotifierProvider<LearningRateNotifier, double>(() {
  return LearningRateNotifier();
});
