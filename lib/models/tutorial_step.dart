import 'package:flutter/material.dart';

/// Defines the UI components that a tutorial step can target/anchor to.
enum TutorialTarget {
  canvas,
  controls,
  taskSelector,
  charts,
  vault,
  profile,
}

/// Represents a single step in the in-app tutorial.
@immutable
class TutorialStep {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final String? actionHint;
  final TutorialTarget target;

  const TutorialStep({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.target,
    this.actionHint,
  });
}
