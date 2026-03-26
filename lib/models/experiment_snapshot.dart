import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';
import 'simulation_state.dart';

@immutable
class ExperimentSnapshot {
  final String id;
  final String userId;
  final String userEmail;
  final String taskName;
  final double finalErrorRate;
  final double? finalVorGain;
  final List<double> synapticWeights;
  final int episodeCount;
  final bool isPublic;
  final String title;
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
