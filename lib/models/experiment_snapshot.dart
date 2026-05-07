import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';
import 'simulation_state.dart';
import 'network_config.dart';
import 'episode_record.dart';

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
  /// Optional researcher notes/annotations.
  final String? notes;
  /// The timestamp when the snapshot was created.
  final DateTime createdAt;
  /// The network topology used in the experiment.
  final NetworkConfig? networkConfig;
  /// The history of learning performance over episodes.
  final List<EpisodeRecord> episodeHistory;

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
    this.notes,
    required this.createdAt,
    this.networkConfig,
    this.episodeHistory = const [],
  });

  /// Converts the snapshot into a Map suitable for storage in Cloud Firestore.
  ///
  /// Validates size bounds client-side (mirrors Firestore rules) so the user
  /// sees a friendly [ArgumentError] instead of a raw `permission-denied`.
  Map<String, dynamic> toFirestore() {
    if (synapticWeights.length > 5000) {
      throw ArgumentError(
          'synapticWeights exceeds the limit of 5,000 weights. '
          'Try a smaller network configuration.');
    }
    if (episodeHistory.length > 200) {
      throw ArgumentError(
          'episodeHistory exceeds the limit of 200 records. '
          'Only the most recent 200 episodes can be saved.');
    }
    if (notes != null && notes!.length > 1000) {
      throw ArgumentError(
          'Notes must be 1,000 characters or fewer '
          '(currently ${notes!.length}).');
    }
    if (userEmail.length > 254) {
      throw ArgumentError('User email exceeds RFC 5321 maximum length.');
    }
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
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
      'networkConfig': networkConfig != null ? {
        'gcCount': networkConfig!.gcCount,
        'bcCount': networkConfig!.bcCount,
        'pcCount': networkConfig!.pcCount,
        'scCount': networkConfig!.scCount,
        'dcnCount': networkConfig!.dcnCount,
      } : null,
      'episodeHistory': episodeHistory.map((e) => e.toJson()).toList(),
    };
  }

  /// Creates an [ExperimentSnapshot] from a Firestore [DocumentSnapshot].
  factory ExperimentSnapshot.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final configData = data['networkConfig'] as Map<String, dynamic>?;
    final historyData = data['episodeHistory'] as List<dynamic>?;

    return ExperimentSnapshot(
      id: doc.id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      taskName: data['taskName'] ?? '',
      finalErrorRate: (data['finalErrorRate'] as num?)?.toDouble() ?? 0.0,
      finalVorGain: (data['finalVorGain'] as num?)?.toDouble(),
      synapticWeights: (data['synapticWeights'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList() ?? [],
      episodeCount: data['episodeCount'] ?? 0,
      isPublic: data['isPublic'] ?? false,
      title: data['title'] ?? 'Untitled Experiment',
      notes: data['notes'],
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      networkConfig: configData != null ? NetworkConfig(
        gcCount: configData['gcCount'] ?? 10,
        bcCount: configData['bcCount'] ?? 5,
        pcCount: configData['pcCount'] ?? 2,
        scCount: configData['scCount'] ?? 1,
        dcnCount: configData['dcnCount'] ?? 2,
      ) : null,
      episodeHistory: historyData?.map((e) => EpisodeRecord.fromJson(e as Map<String, dynamic>)).toList() ?? [],
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
    String? notes,
    required bool isPublic,
    required SimulationState state,
    required List<EpisodeRecord> episodeHistory,
    NetworkConfig? networkConfig,
  }) {
    return ExperimentSnapshot(
      id: '', // Will be set by Firestore
      userId: userId,
      userEmail: userEmail,
      taskName: taskName,
      finalErrorRate: episodeHistory.isNotEmpty 
        ? episodeHistory.last.meanPunishment 
        : state.climbingFiberSignal,
      finalVorGain: state.rollingGainRatio,
      synapticWeights: state.synapses.map((s) => s.weight).toList(),
      episodeCount: state.episodeCount,
      isPublic: isPublic,
      title: title,
      notes: notes,
      createdAt: DateTime.now(),
      networkConfig: networkConfig,
      episodeHistory: List.from(episodeHistory),
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
    String? notes,
    DateTime? createdAt,
    NetworkConfig? networkConfig,
    List<EpisodeRecord>? episodeHistory,
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
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      networkConfig: networkConfig ?? this.networkConfig,
      episodeHistory: episodeHistory ?? this.episodeHistory,
    );
  }

  /// Converts the snapshot to a JSON string for export.
  /// Excludes userId for privacy.
  String toJson() {
    final map = {
      'userEmail': userEmail,
      'taskName': taskName,
      'finalErrorRate': finalErrorRate,
      'finalVorGain': finalVorGain,
      'synapticWeights': synapticWeights,
      'episodeCount': episodeCount,
      'isPublic': isPublic,
      'title': title,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'networkConfig': networkConfig != null ? {
        'gcCount': networkConfig!.gcCount,
        'bcCount': networkConfig!.bcCount,
        'pcCount': networkConfig!.pcCount,
        'scCount': networkConfig!.scCount,
        'dcnCount': networkConfig!.dcnCount,
      } : null,
      'episodeHistory': episodeHistory.map((e) => e.toJson()).toList(),
    };
    return jsonEncode(map);
  }

  /// Creates a snapshot from a JSON string.
  factory ExperimentSnapshot.fromJson(String jsonStr, {String? currentUserId}) {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    final configData = data['networkConfig'] as Map<String, dynamic>?;
    final historyData = data['episodeHistory'] as List<dynamic>?;

    return ExperimentSnapshot(
      id: '', // Temporary ID
      userId: currentUserId ?? data['userId'] ?? '',
      userEmail: data['userEmail'] ?? 'imported',
      taskName: data['taskName'] ?? '',
      finalErrorRate: (data['finalErrorRate'] as num?)?.toDouble() ?? 0.0,
      finalVorGain: (data['finalVorGain'] as num?)?.toDouble(),
      synapticWeights: (data['synapticWeights'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList() ?? [],
      episodeCount: data['episodeCount'] ?? 0,
      isPublic: data['isPublic'] ?? false,
      title: data['title'] ?? 'Imported Experiment',
      notes: data['notes'],
      createdAt: data['createdAt'] != null ? DateTime.parse(data['createdAt']) : DateTime.now(),
      networkConfig: configData != null ? NetworkConfig(
        gcCount: configData['gcCount'] ?? 10,
        bcCount: configData['bcCount'] ?? 5,
        pcCount: configData['pcCount'] ?? 2,
        scCount: configData['scCount'] ?? 1,
        dcnCount: configData['dcnCount'] ?? 2,
      ) : null,
      episodeHistory: historyData?.map((e) => EpisodeRecord.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    );
  }
}
