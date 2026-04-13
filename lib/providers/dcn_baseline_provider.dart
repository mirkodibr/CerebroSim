import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/simulation_constants.dart';

/// A notifier that manages the baseline drive for DCN neurons.
/// This represents the spontaneous tonic firing rate of the cerebellar output.
class DcnBaselineProvider extends Notifier<double> {
  @override
  double build() => SimulationConstants.kDcnBaselineDrive;

  set value(double v) => state = v;
}

/// A global provider for the [DcnBaselineProvider].
final dcnBaselineProvider = NotifierProvider<DcnBaselineProvider, double>(() {
  return DcnBaselineProvider();
});
