# CerebroSim — Cerebellar RL Research Lab

A high-fidelity Flutter application simulating cerebellar motor learning using Leaky Integrate-and-Fire (LIF) neurons and Temporal Difference (TD) reinforcement learning, based on the Marr-Albus-Ito theory and modern Actor-Critic frameworks.

## What It Does
CerebroSim lets you watch a biologically-inspired neural network learn three classic cerebellar tasks in real time:

* **Delay Eyeblink Conditioning** — Associative learning where the network utilizes eligibility traces to bridge the gap between a neutral stimulus and an airpuff.
* **Sine Wave Tracking** — Continuous signal prediction requiring the network to match a moving target using directional slope analysis.
* **VOR Adaptation** — Vestibulo-ocular reflex calibration, simulating healthy and ataxic gain states through error-signal integration.

The simulation runs at 60Hz, visualized as an interactive 3D-parallax cerebellar microcircuit with specialized vertical layers for the Molecular, Purkinje, and Granular zones.

## Architecture
Strict adherence to separation of concerns ensures a research-grade codebase:
* **lib/models/**: Immutable Dart data classes (`Neuron`, `Synapse`) representing the physical architecture.
* **lib/services/**: Pure Dart logic including the spiking engine, LIF dynamics, and TD-learning rules.
* **lib/providers/**: Riverpod 3 notifiers bridging environmental state and neural simulation.
* **lib/widgets/**: Optimized UI components including the GPU-accelerated `NeuralCanvas` and real-time `SignalPlotter`.

## Design Principles
* **No setState for business logic**: All state changes are handled exclusively through Riverpod Notifiers.
* **High-Contrast "Cyber-Lab" Aesthetic**: Deep charcoal (#121212) background with Neon Cyan (#00E5FF) indicators for neural activity.
* **Atomic Cloud Writes**: Firebase Firestore integration ensures research snapshots are saved with complete integrity.

## Neuroscience Background
The model implements a modern interpretation of the Marr-Albus-Ito theory:
* **Granule Cells (GC)**: Encode sensory context via Parallel Fibers with spatial tiling.
* **Purkinje Cells (PC)**: The "Actor" layer that integrates input to inhibit motor output.
* **Stellate Cells (SC)**: The "Critic" layer providing predicted punishment signals.
* **Deep Cerebellar Nuclei (DCN)**: The output action selection layer with baseline excitatory drive.

## Getting Started
### Prerequisites
* Flutter SDK (Stable Channel)
* Firebase project with Auth and Firestore enabled
* `lib/firebase_options.dart` generated via `flutterfire configure`

### Setup
```bash
git clone <repo>
cd cerebrosim
flutter pub get
flutter run