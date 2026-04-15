import 'package:meta/meta.dart';

/// Configuration for dynamically generating a cerebellar neural network.
/// 
/// This allows the simulation to scale beyond hardcoded microcircuits.
@immutable
class NetworkConfig {
  final int gcCount;
  final int bcCount;
  final int pcCount;
  final int scCount;
  final int dcnCount;

  const NetworkConfig({
    required this.gcCount,
    required this.bcCount,
    required this.pcCount,
    required this.scCount,
    required this.dcnCount,
  });

  /// The standard baseline configuration for a minimal functional circuit.
  factory NetworkConfig.defaultConfig() {
    return const NetworkConfig(
      gcCount: 10,
      bcCount: 5,
      pcCount: 2,
      scCount: 1,
      dcnCount: 2,
    );
  }

  /// Returns a copy of the configuration with updated fields.
  NetworkConfig copyWith({
    int? gcCount,
    int? bcCount,
    int? pcCount,
    int? scCount,
    int? dcnCount,
  }) {
    return NetworkConfig(
      gcCount: gcCount ?? this.gcCount,
      bcCount: bcCount ?? this.bcCount,
      pcCount: pcCount ?? this.pcCount,
      scCount: scCount ?? this.scCount,
      dcnCount: dcnCount ?? this.dcnCount,
    );
  }
}
