import 'package:flutter/material.dart';
import '../models/tutorial_step.dart';

/// The full list of steps in the CerebroSim in-app tutorial.
const List<TutorialStep> kTutorialSteps = [
  TutorialStep(
    id: 'step_task_selector',
    target: TutorialTarget.taskSelector,
    icon: Icons.psychology,
    title: "Choose Your Task",
    description: "Select from Eyeblink, Sine Wave, VOR, or Arm Reaching. Each trains the cerebellum on a different biological problem.",
  ),
  TutorialStep(
    id: 'step_controls',
    target: TutorialTarget.controls,
    icon: Icons.play_arrow,
    title: "Start the Simulation",
    description: "Tap the play button to begin. The network will start making errors and learning from them in real time.",
  ),
  TutorialStep(
    id: 'step_canvas_gestures',
    target: TutorialTarget.canvas,
    icon: Icons.gesture,
    title: "Explore the Neural Canvas",
    description: "Swipe to rotate the 3D view, pinch to zoom, and tap any neuron to inspect its membrane potential and firing state.",
  ),
  TutorialStep(
    id: 'step_canvas_colors',
    target: TutorialTarget.canvas,
    icon: Icons.palette,
    title: "Read the Neuron Colors",
    description: "Gold = Granule Cells (input), Purple = Purkinje Cells (output gating), Teal = DCN (motor output), Red = Climbing Fiber (error signal).",
  ),
  TutorialStep(
    id: 'step_charts_plotter',
    target: TutorialTarget.charts,
    icon: Icons.show_chart,
    title: "Watch the Signal Plotter",
    description: "Cyan is the network's prediction, Amber is the actual error signal. They converge as the network learns.",
  ),
  TutorialStep(
    id: 'step_charts_convergence',
    target: TutorialTarget.charts,
    icon: Icons.trending_down,
    title: "Track Convergence",
    description: "The lower chart shows mean punishment (Red) and TD error (Cyan) across episodes. Downward trend means learning.",
  ),
  TutorialStep(
    id: 'step_speed_params',
    target: TutorialTarget.controls,
    icon: Icons.speed,
    title: "Adjust Speed & Parameters",
    description: "Use 1×/5×/10× speed to run experiments faster. Tap the task config panel to tune biological parameters like CS duration or VOR gain.",
  ),
  TutorialStep(
    id: 'step_vault',
    target: TutorialTarget.vault,
    icon: Icons.bookmark,
    title: "Save Your Experiments",
    description: "Tap the bookmark icon to save a snapshot of your network's learned weights. Load them later from the Vault to resume or compare.",
  ),
];
