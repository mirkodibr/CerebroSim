# Project Requirements: CerebroSim Mobile Lab
**Developer:** Mirko Dibra
**Description:** A professional-grade mobile neural research lab that simulates cerebellar learning and motor coordination based on the Marr-Albus-Ito theory.

## AI Assistant Guardrails
Gemini: When reading this file to implement a step, you MUST adhere to the following architectural rules:
1. [ ]**State Management:** Use `flutter_riverpod` exclusively. [cite_start]Do not use `setState` for complex logic.
2. [ ]**Architecture:** Maintain strict separation of concerns into `/models` (data classes), `/services` (backend/logic), `/providers` (Riverpod logic), and `/screens` (UI) .
3. [ ]**Local Storage:** Use `shared_preferences` for theme toggles and onboarding status.
4. [ ]**Database:** Use **Firebase Firestore** for persistent cloud research data.
5. **Stepwise Execution:** Only implement the specific sub-step requested. [cite_start]Do not jump ahead.

---

## Implementation Roadmap

### Phase 1: Project Setup & Core Infrastructure
* [x]**Step 1.1: Environment Configuration:** Add `flutter_riverpod`, `firebase_core`, `firebase_auth`, `cloud_firestore`, and `shared_preferences` to `pubspec.yaml`.
* [x]**Step 1.2: Platform Initialization:** Configure Firebase for Android/iOS and initialize it in `main.dart`.
* [x]**Step 1.3: Visual Foundation:** Create a centralized `ThemeData` class in `lib/theme.dart` for consistent typography and colors.
* [x]**Step 1.4: Base Architecture:** Set up the folder structure [x] and wrap the root widget in a `ProviderScope` [x].

### Phase 2: Milestone 1 - The Minimum Viable Product (MVP)
*Goal: The core defining feature (Neural Simulation) must function with local state.*

* [x]**Step 2.1: Spiking Neural Data Models:** * [x]**2.1.1:** Define immutable Dart classes for `Neuron` (threshold, potential) and `Synapse` (weight) in `/models`.
    * [x]**2.1.2:** Create a `SimulationState` model to hold snapshots of all active cells.
* [x]**Step 2.2: Simulation Engine (Logic Layer):** 
    * [x]**2.2.1:** Build `SimulationService` in `/services` to process discrete spiking dynamics.
    * [x]**2.2.2:** Implement the **Climbing Fiber** error-correction logic to adjust synaptic weights.
* [x]**Step 2.3: State & Timing:** * [x]
    * [x]**2.3.1:** Create a Riverpod `Notifier` to act as the simulation clock at 60fps.
    * [x]**2.3.2:** Implement a provider to generate target input signals (Sine, Noisy waves).
* [x]**Step 2.4: The Neural Canvas (UI Layer):** * [x]
    * [x]**2.4.1:** Implement a `CustomPainter` widget to draw the 2D layout of the cerebellar cortex.
    * [x]**2.4.2:** Wrap the canvas in an `InteractiveViewer` for zoom/pan support.
* [x]**Step 2.5: Real-Time Signal Plotter:** Build a dedicated graphing widget to visualize input vs. output in real-time.
### Phase 2.5: Actor-Critic RL Refactor (Kuriyama et al. 2025)
*Goal: Transition the core simulation engine from classical Supervised Learning to Continuous-Time Reinforcement Learning.*

* [x]**Step 2.5.1: RL Data Models:** Update `Neuron` with LIF (Leaky Integrate-and-Fire) dynamics (`decayRate`) and `actionGroup`. Update `Synapse` with `eligibilityTrace` and `targetType`.
* [x]**Step 2.5.2: State Engine & Traces:** Refactor `SimulationService.calculateNextState` to process potential decay (LIF) and update synapse eligibility traces upon presynaptic spikes.
* [x]**Step 2.5.3: Actor-Critic Learning Rule:** Implement `adjustWeightsRL` in `SimulationService`. Calculate predicted value via Stellate Cells (Critic) and action output via Deep Cerebellar Nuclei (DCN). Use TD Error and eligibility traces to update weights.
* [x]**Step 2.5.4: Episodic Environment:** Refactor the input provider into an `EnvironmentProvider` that manages episodic runs, outputs state to Parallel Fibers, and triggers continuous Climbing Fiber punishment signals.
* [x]**Step 2.5.5: Visualization Updates:** Update `NeuralCanvas` to draw SC, BC, and DCN cells. Update `SignalPlotter` to graph the Critic's value prediction and success rate over episodes.

### Phase 3: Milestone 2 - Full Stack Integration
[ ]*Goal: Complete major functionality and replace mock data with live cloud and authentication.*

* [ ]**Step 3.1: Secure Identity (Authentication):** * **3.1.1:** Implement `AuthService` using Firebase Authentication.
* [ ]**3.1.2:** Configure **Google Sign-In** alongside standard Email/Password.
* [ ]**Step 3.2: The Auth Gate:** Create an `AuthGate` widget to handle automatic redirection based on user login state.
* [ ]**Step 3.3: Cloud Research Vault (Database):** * **3.3.1:** Implement `DatabaseService` using Firestore for persistent storage.
* [ ]**3.3.2:** Create CRUD operations to save/fetch "Brain State" snapshots (weights/maps).
* **Step 3.4: Cloud Gallery UI:** Build a screen to browse, preview, and load saved simulations from the cloud.

### Phase 4: Polish & Professional Persistence
* [ ]**Step 4.1: Local Persistence:** Use `shared_preferences` to implement a "Dark Mode" toggle
* [ ]**Step 4.2: Robust UX:** Implement `AsyncValue.when()` across all UI to handle loading and error states.
* [ ]**Step 4.3: Final Refactoring:** Break down any files larger than 200 lines by extracting widgets into `/widgets`.