import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/simulation_constants.dart';

/// A notifier that manages the discount factor (gamma) for TD learning.
/// Gamma determines the importance of future rewards in the cerebellar prediction.
class GammaNotifier extends Notifier<double> {
  @override
  double build() => SimulationConstants.kDefaultGamma;

  set value(double v) => state = v;
}

/// A global provider for the [GammaNotifier].
final gammaProvider = NotifierProvider<GammaNotifier, double>(() {
  return GammaNotifier();
});
