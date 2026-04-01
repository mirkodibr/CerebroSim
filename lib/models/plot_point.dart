import 'package:meta/meta.dart';

@immutable
class PlotPoint {
  final double criticPrediction;
  final double actualSignal;
  final double gainRatio;

  const PlotPoint({
    required this.criticPrediction,
    required this.actualSignal,
    this.gainRatio = 0.0,
  });
}
