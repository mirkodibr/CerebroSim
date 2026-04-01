import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';
import 'simulation_state.dart';

/// Represents a saved state of a cerebellar simulation experiment.
///
/// This class is used to persist simulation results, including synaptic weights
/// and performance metrics, to Firestore and to reload them for later analysis.
@immutable
class ExperimentSnapshot {
  /// Unique identifier for the snapshot.
  final String id;
  /// The ID of the user who created the snapshot.
  final String userId;
  /// The email of the user who created the snapshot.
  final String userEmail;
  /// The name of the task being simulated (e.g., "VOR").
  final String taskName;
  /// The final error rate achieved at the end of the experiment.
  final double finalErrorRate;
  /// The final VOR gain ratio, specifically for VOR tasks.
  final double? finalVorGain;
  /// The list of synaptic weights across the network at the time of the snapshot.
  final List<double> synapticWeights;
  /// The total number of episodes completed in the experiment.
  final int episodeCount;
  /// Whether this experiment result is visible to other users.
  final bool isPublic;
  /// A descriptive title for the experiment.
  final String title;
  /// The timestamp when the snapshot was created.
  final DateTime createdAt;

  const ExperimentSnapshot({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.taskName,
    required this.finalErrorRate,
    this.finalVorGain,
    required this.synapticWeights,
    required this.episodeCount,
    required this.isPublic,
    required this.title,
    required this.createdAt,
  });

  /// Converts the snapshot into a Map suitable for storage in Cloud Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'taskName': taskName,
      'finalErrorRate': finalErrorRate,
      'finalVorGain': finalVorGain,
      'synapticWeights': synapticWeights,
      'episodeCount': episodeCount,
      'isPublic': isPublic,
      'title': title,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Creates an [ExperimentSnapshot] from a Firestore [DocumentSnapshot].
  factory ExperimentSnapshot.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExperimentSnapshot(
      id: doc.id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      taskName: data['taskName'] ?? '',
      finalErrorRate: (data['finalErrorRate'] as num?)?.toDouble() ?? 0.0,
      finalVorGain: (data['finalVorGain'] as num?)?.toDouble(),
      synapticWeights: List<double>.from((data['synapticWeights'] as List<dynamic>?) ?? []),
      episodeCount: data['episodeCount'] ?? 0,
      isPublic: data['isPublic'] ?? false,
      title: data['title'] ?? 'Untitled Experiment',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Creates a snapshot from the current [SimulationState] and user metadata.
  ///
  /// This captures the current performance and weights to be saved.
  factory ExperimentSnapshot.fromSimulation({
    required String userId,
    required String userEmail,
    required String taskName,
    required String title,
    required bool isPublic,
    required SimulationState state,
  }) {
    return ExperimentSnapshot(
      id: '', // Will be set by Firestore
      userId: userId,
      userEmail: userEmail,
      taskName: taskName,
      finalErrorRate: state.tdError.abs(), // Simplified error rate
      finalVorGain: state.rollingGainRatio,
      synapticWeights: state.synapses.map((s) => s.weight).toList(),
      episodeCount: state.episodeCount,
      isPublic: isPublic,
      title: title,
      createdAt: DateTime.now(),
    );
  }

  /// Returns a copy of this snapshot with updated fields.
  ExperimentSnapshot copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? taskName,
    double? finalErrorRate,
    double? finalVorGain,
    List<double>? synapticWeights,
    int? episodeCount,
    bool? isPublic,
    String? title,
    DateTime? createdAt,
  }) {
    return ExperimentSnapshot(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      taskName: taskName ?? this.taskName,
      finalErrorRate: finalErrorRate ?? this.finalErrorRate,
      finalVorGain: finalVorGain ?? this.finalVorGain,
      synapticWeights: synapticWeights ?? this.synapticWeights,
      episodeCount: episodeCount ?? this.episodeCount,
      isPublic: isPublic ?? this.isPublic,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
