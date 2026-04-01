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
