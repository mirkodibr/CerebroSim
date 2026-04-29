import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/experiment_snapshot.dart';
import '../services/interpretation_service.dart';

class InterpretationSheet extends ConsumerStatefulWidget {
  final ExperimentSnapshot snapshot;

  const InterpretationSheet({super.key, required this.snapshot});

  @override
  ConsumerState<InterpretationSheet> createState() => _InterpretationSheetState();
}

class _InterpretationSheetState extends ConsumerState<InterpretationSheet> {
  late Future<String> _interpretationFuture;
  final List<String> _loadingTexts = [
    "Generating neuroscience interpretation...",
    "Analyzing convergence curve...",
    "Consulting Ito 1984...",
  ];
  int _loadingIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _interpretationFuture = interpretationServiceProvider.interpretExperiment(
      snapshotId: widget.snapshot.id,
      finalErrorRate: widget.snapshot.finalErrorRate,
      taskName: widget.snapshot.taskName,
      episodeCount: widget.snapshot.episodeCount,
    );
    
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _loadingIndex = (_loadingIndex + 1) % _loadingTexts.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI Interpretation',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: FutureBuilder<String>(
              future: _interpretationFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LinearProgressIndicator(),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          _loadingTexts[_loadingIndex],
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],
                  );
                }

                if (snapshot.hasError) {
                  final error = snapshot.error;
                  String message = "Interpretation unavailable.";
                  if (error is FirebaseException) {
                    if (error.code == 'unavailable' || error.code == 'deadline-exceeded') {
                      message = "AI interpretation requires an internet connection.";
                    } else if (error.code == 'failed-precondition') {
                      message = "Interpretation service not configured.";
                    }
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _interpretationFuture = interpretationServiceProvider.interpretExperiment(
                              snapshotId: widget.snapshot.id,
                              finalErrorRate: widget.snapshot.finalErrorRate,
                              taskName: widget.snapshot.taskName,
                              episodeCount: widget.snapshot.episodeCount,
                            );
                          });
                        },
                        child: const Text("Retry"),
                      ),
                    ],
                  );
                }

                return SingleChildScrollView(
                  child: Text(
                    snapshot.data ?? "No interpretation provided.",
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
