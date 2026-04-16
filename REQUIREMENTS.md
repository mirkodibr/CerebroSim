# Project Requirements: CerebroSim Mobile Lab
**Developer:** Mirko Dibra
**Description:** A professional-grade mobile neural research lab that simulates cerebellar learning and motor coordination based on the Marr-Albus-Ito theory using Temporal Difference (TD) learning and Leaky Integrate-and-Fire (LIF) dynamics.

## AI Assistant Guardrails
Gemini: When reading this file to implement a step, you MUST adhere to the following architectural rules:
1. **State Management:** Use `flutter_riverpod` exclusively. Do not use `setState` for complex logic or data mutations.
2. **Architecture:** Maintain strict separation of concerns:
   * `/models`: Pure Dart, immutable data classes (`@immutable`, `copyWith`).
   * `/services`: Pure Dart backend/logic (no Flutter dependencies, no Riverpod).
   * `/providers`: Riverpod Notifiers that bridge Services and UI.
   * `/screens` & `/widgets`: Flutter UI components (`ConsumerWidget`, `ConsumerStatefulWidget`).
3. **Local Storage:** Use `shared_preferences` for theme toggles and onboarding status.
4. **Database:** Use **Firebase Firestore** for persistent cloud research data and snapshots.
5. **Stepwise Execution:** Only implement the specific sub-step requested in the current prompt. Do not jump ahead.

---

## Implementation Roadmap

### Phase 0: Project Reset & Data Models
*Goal: Establish strict, immutable data structures for the simulation.*
* [x] **Neuron & Synapse Models:** Define immutable Dart classes `NeuronModel` (LIF dynamics, eligibility traces) and `SynapseModel` (weights).
* [x] **Simulation Constants:** Centralize learning rates, decay rates, and thresholds in a static class.
* [x] **State Model:** Create `SimulationState` to hold snapshots of all active cells, TD error, and punishment signals.

### Phase 1: Project Setup & Core Infrastructure
*Goal: Initialize the app, inject dependencies, and start the engine.*
* [x] **Dependencies:** Integrate `flutter_riverpod`, `firebase_core`, `cloud_firestore`, and `shared_preferences`.
* [x] **App Initialization:** Ensure `WidgetsFlutterBinding` and `Firebase.initializeApp` run asynchronously before `runApp`.
* [x] **Provider Scope:** Wrap the root widget in a `ProviderScope`.

### Phase 2: Theming & Navigation Shell
*Goal: Build the foundational UI wrapper and routing mechanism.*
* [x] **Theme Service:** Create a dual-theme system (Cyber Lab Dark Mode vs. Presentation Light Mode).
* [x] **Theme Persistence:** Persist user theme choices using `shared_preferences`.
* [x] **App Shell:** Implement a `BottomNavigationBar` routing to Simulate, Vault, and Profile screens.

### Phase 3: Identity & Authentication
*Goal: Secure the application and prepare for cloud syncing.*
* [x] **Auth Service:** Implement Firebase Authentication for Email/Password and Google Sign-In.
* [x] **Auth Provider:** Create a Riverpod state watcher for the current user session.
* [x] **Auth UI:** Build robust Login and Register screens with form validation.
* [x] **Route Guard:** Automatically redirect users to the AppShell or Login screen based on auth state.

### Phase 4: Simulation Engine (Logic Layer)
*Goal: Build a highly performant, pure-Dart simulation engine.*
* [x] **Environment Interface:** Define `EnvironmentStep` for tasks to communicate with the engine.
* [x] **LIF & Eligibility:** Implement Leaky Integrate-and-Fire membrane decay and eligibility trace tracking.
* [x] **TD Learning:** Implement Temporal Difference error calculations using Climbing Fiber (actual) and DCN/Critic (predicted) signals.
* [x] **Clock & Ticker:** Create a `SimulationNotifier` that ticks the engine at 60Hz.

### Phase 5: Neural Canvas Visualisation
*Goal: Render the cerebellar microcircuit interactively.*
* [x] **Custom Painter:** Build `NeuralCanvasPainter` to draw neurons (GC, PC, BC, DCN, CF) and synapses.
* [x] **Layer Rendering:** Color-code layers (Molecular, Purkinje, Granular) and visually indicate firing states and synaptic weights.
* [x] **Tap-to-Inspect:** Implement an interactive bottom sheet to view real-time membrane potentials and traces of tapped cells.

### Phase 6: Task Environments & Telemetry
*Goal: Expose the network to biological learning scenarios.*
* [x] **Eyeblink Conditioning:** Implement delay fear conditioning (Tone -> Airpuff).
* [x] **Sine Wave Tracking:** Implement continuous target tracking with directional punishment.
* [x] **VOR Adaptation:** Implement Vestibulo-Ocular Reflex calibration with variable gain setups.
* [x] **Signal Plotter:** Build a real-time rolling graph comparing Critic Prediction, Actual Punishment, and Task Gain.
* [x] **Task Selector:** Allow users to dynamically swap environments while the simulation runs.

### Phase 7: Guided Onboarding
*Goal: Explain complex neurobiology to first-time users.*
* [x] **Watch Mode:** Introduce the concept of error-driven learning with an auto-playing simulation.
* [x] **Control Mode:** Allow users to manipulate the learning rate and observe the plotter.
* [x] **Explore Mode:** Teach the user how to inspect cells using tooltips and descriptions.

### Phase 8: Cloud Research Vault
*Goal: Allow users to save, share, and reload their experiments.*
* [x] **Experiment Snapshot:** Create a model to serialize network weights, error rates, and task parameters.
* [x] **Database Service:** Wire up Firestore to save to private user collections and public galleries.
* [x] **Vault UI:** Build a tabbed interface to browse personal history vs. community experiments.
* [x] **Load State:** Allow users to load a snapshot from the Vault directly back into the live Simulation Engine.

### Phase 9: Polish & Submission Prep
*Goal: Finalize the app for portfolio/production readiness.*
* [x] **Error Handling:** Ensure all async operations have `try/catch` blocks and user-facing SnackBars.
* [x] **Loading States:** Implement `CircularProgressIndicator` or shimmers for all `AsyncLoading` states.
* [x] **Code Audit:** Ensure no file exceeds 200 lines; extract complex UI into dedicated widgets.
### Phase 10: Architectural Hardening & Data Integrity
*Goal: Secure the simulation against state drift and ensure atomic cloud operations.*
* [x] **State Synchronization:** Decouple `SignalPlotter` telemetry from the Flutter build cycle to ensure data points are only generated on biological ticks.
* [x] **Parameter Injection:** Refactor the `SimulationEngine` to accept learning rates, gamma, and DCN baseline values as dynamic inputs from providers rather than hardcoded constants.
* [x] **Atomic Research Vault:** Implement `WriteBatch` for all Firestore operations to ensure experiments are saved to personal history and public galleries simultaneously or not at all.
* [x] **Resource Safety:** Audit all `AsyncNotifiers` to ensure `StreamSubscriptions` and `Timers` are explicitly cancelled via `ref.onDispose` to prevent memory leaks.

### Phase 11: Longitudinal Analytics & Simulation Control
*Goal: Visualize long-term learning curves and enable high-speed experimentation.*
* [x] **Convergence Tracking:** Create an `EpisodeHistoryProvider` to track `Mean Punishment` and `Final TD-Error` across multiple simulation runs.
* [x] **Episode Records:** Implement an immutable `EpisodeRecord` model to store performance telemetry for a sliding window of the last 50 episodes.
* [x] **Convergence Chart:** Build a dual-line visualizer (Red: Punishment, Cyan: TD-Error) to show how the network converges toward a solution over time.
* [x] **Time Dilation:** Implement variable simulation speeds (1×, 5×, 10×) and a non-resetting "Pause" state for precise observation mid-episode.

### Phase 12: 3D Visualization & Interactive Projection
*Goal: Transform the simulation into a spatial, depth-aware neurobiological model.*
* [x] **Projection Utilities:** Implement a pure-Dart 3D math engine with rotation matrices and perspective divide logic ($S = \text{zoom} / (z + 4.0)$).
* [x] **3D Neural Canvas:** Replace the 2D painter with a 3D version that utilizes the Painter’s Algorithm for depth-sorted rendering of neurons and synapses.
* [x] **Gesture-Based Navigation:** Enable interactive rotation (X/Y axes) and pinch-to-zoom using `ScaleGestureDetector` on the 3D workspace.
* [x] **Biological Overlays:** Add live 3D electrical "charge arcs" on each cell and a smart-positioning `NeuronInfoOverlay` card that tracks selected neurons in 3D space.

### Phase 13: Engine Optimization (The Performance Fix)
*Goal: Eliminate O(N) list traversals to allow the engine to maintain 60fps when scaling to hundreds of neurons.*
* [x] **O(1) State Overhaul:** Refactor `SimulationState` to store `neurons` as a `Map<String, NeuronModel>`.
* [x] **Synapse Indexing:** Implement a pre-computed adjacency list (`Map<String, List<SynapseModel>>`) for instant outbound connection lookups.
* [x] **Tick Refactor:** Rewrite `SimulationEngine.tick` to utilize map-based routing instead of `.firstWhere` lookups.

### Phase 14: Temporal Dynamics (The Biology Fix)
*Goal: Replace instantaneous transmission with biologically realistic parallel fiber travel times.*
* [x] **Delay Modeling:** Add an `int axonalDelay` property to the `SynapseModel`.
* [x] **The Ring Buffer:** Implement a temporal ring buffer inside `SimulationEngine` to schedule potential delivery for `currentTick + axonalDelay`.

### Phase 15: Dynamic Topology & Complex Tasks
*Goal: Break the hardcoded 19-neuron limit and introduce multi-dimensional motor control.*
* [x] **Network Configuration:** Create a `NetworkConfig` model allowing custom counts for GC, BC, PC, SC, and DCN cells.
* [x] **Procedural Architecture:** Refactor `NetworkInitializer` to procedurally generate connections and `NeuralCanvas3DPainter` to dynamically position cells based on layer counts.
* [x] **2D Arm Reaching Task:** Expand the `EnvironmentProvider` and DCN logic to support a 2-dimensional (X/Y) planar reaching task with continuous Euclidean distance punishment.

### Phase 16 : Critical Blockers (Production Hardening)
*Goal: Resolve App Store blockers, prevent silent failures, and fix architectural state drift before scaling the engine.*
* [x] **Bundle ID & Metadata:** Replace placeholder bundle identifiers across all platforms to meet App Store and Firebase OAuth requirements.
* [x] **Crashlytics Integration:** Implement Firebase Crashlytics to catch and report asynchronous and frame-level errors in production.
* [x] **Unified Network Builder:** Centralize all network topology generation inside `NetworkInitializer` to prevent state drift and failing CI tests.
* [ ] **Offline & Lifecycle Management:** Enable Firestore offline persistence and use `AppLifecycleListener` to pause the 60Hz ticker when backgrounded.
* [ ] **Account Deletion Flow:** Implement a complete, batch-based account deletion feature to comply with GDPR and App Store mandates.
* [ ] **Auth & State Fixes:** Enforce email verification for public saves and ensure simulation buffers are cleared during task switching.

### Phase 17 : Quality & Navigation
*Goal: Implement declarative routing, a native launch experience, and ensure complete UI theme consistency.*
* [ ] **Declarative Routing:** Migrate imperative `Navigator` logic to `go_router` with Riverpod auth-redirect guards to prevent stack corruption.
* [ ] **Native Splash Screen:** Implement `flutter_native_splash` to hold the launch screen until Firebase Auth is initialized.
* [ ] **Theme Token Audit:** Replace all hardcoded colors (e.g., `Colors.white`) with `Theme.of(context).colorScheme` tokens for flawless Light/Dark mode transitions.
* [ ] **Vault & Save UX:** Add loading states to the save operation and implement client-side filtering/sorting for the Vault gallery.

### Phase 18 : Neuron Count Configurator
*Goal: Expose network topology parameters to the user for dynamic architectural scaling.*
* [ ] **Configurator UI:** Build a dedicated screen allowing users to increment/decrement GC, BC, PC, SC, and DCN neuron counts within safe limits.
* [ ] **Engine Integration:** Inject the user-defined `NetworkConfig` into the `SimulationEngine` and serialize it within `ExperimentSnapshot` saves.

### Phase 19 : UI/UX Polish and Layout Fixes
*Goal: Elevate the app from a functional prototype to a premium, professional-grade research tool.*
* [ ] **Layout Overhaul:** Refactor the Simulate screen using `CustomScrollView` and `SliverList` to prevent overflow and improve data density.
* [ ] **Chart Readability:** Add horizontal gridlines, Y-axis scale labels, and current-value legends to the `ConvergenceChart` and `SignalPlotter`.
* [ ] **Tactile & Discoverability:** Implement `HapticFeedback` on interactions, a first-launch 3D gesture hint, and onboarding state restoration.
* [ ] **Premium Styling:** Apply high-fidelity UI constraints (compact chips, consistent gap spacing, subtle card borders, flat app bars).
* [ ] **Parameter Sliders:** Add dynamic configuration sliders for the Eyeblink (CS window) and Sine Wave (Frequency/Amplitude) tasks.

### Phase 20: Differentiating Features
*Goal: Introduce virality, AI interpretation, and educational value to capture the academic and institutional market.*
* [ ] **Export & Deep Linking:** Enable JSON export of private experiments via `share_plus` and `cerebrosim://` deep-linking for public snapshots.
* [ ] **AI-Powered Interpretation:** Integrate a Firebase Cloud Function to query Anthropic's API, translating raw simulation data into plain-English neuroscience insights.
* [ ] **Guided Experiments Mode:** Build an interactive educational mode featuring pre-configured experiments linked to foundational neuroscience papers.