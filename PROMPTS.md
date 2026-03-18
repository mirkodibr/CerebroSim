# PROMPTS.md: CerebroSim Development Log

**Phase 1: Project Setup & Core Infrastructure**
[x] 1. Read the `REQUIREMENTS.md` file for architectural guardrails
[x] 2. **Dependency Injection:** Add `flutter_riverpod`, `firebase_core`, `firebase_auth`, `cloud_firestore`, and `shared_preferences` to the `pubspec.yaml` file. Ensure all dependencies are compatible with the latest stable Flutter version and run `flutter pub get`.
[x] 3. **Directory Architecture:** Create the following directory structure within the `lib/` folder: `/models`, `/screens`, `/widgets`, `/services`, and `/providers`. Add a placeholder `.gitkeep` file in each to ensure they are tracked by Git.
[x] 4. **Thematic Palette:** Create a file `lib/theme.dart`. Define a `CerebroTheme` class containing a `static ThemeData` object . Use a deep charcoal (#121212) for the primary background and a high-contrast neon cyan (#00E5FF) for primary accents to represent neural activity.
[x] 5. **Scientific Typography:** Update the `ThemeData` in `lib/theme.dart` to include a custom `TextTheme`. Use a clean, sans-serif font optimized for legibility of scientific data and numerical readouts.
[x] 6. **Async Initialization:** Update `main.dart` to make the `main()` function `async`. Add `WidgetsFlutterBinding.ensureInitialized()` and `await Firebase.initializeApp()` to ensure the backend is ready before the app launches. 
[x] 7. **Root ProviderScope:** In `main.dart`, wrap the `CerebroSimApp` widget in a `ProviderScope`. This is the required step to enable Riverpod state management throughout the entire application.
[x] 8. **Initial Scaffold:** Create `lib/screens/home_screen.dart` with a basic `Scaffold` and a `Center` widget displaying "CerebroSim Initialized". Apply the `ThemeData` defined in Step 3 to the `MaterialApp` in `main.dart`.

**Phase 2: Milestone 1 - The Minimum Viable Product (MVP)**

[x] 9. **Neuron Data Model:** Create a pure Dart class `Neuron` in the `/models` directory. Include immutable properties for `id`, `type` (e.g., Granular, Purkinje), `threshold`, and `currentPotential`. Add a `copyWith` method to enable efficient state updates.

[x] 10. **Synapse Data Model:** Create a pure Dart class `Synapse` in the `/models` directory to represent connections. It should include properties for `sourceId`, `targetId`, `weight`, and `learningRate` to satisfy the plasticity requirements of the Marr-Albus-Ito theory.

[x] 11. **Simulation State Model:** Create a `SimulationState` model in `/models` that holds a `List<Neuron>` and a `List<Synapse>`. This class will represent the full snapshot of the brain’s architecture at any given millisecond.

[x] 12. **The Spiking Engine Logic:** Build a `SimulationService` in `/services`. Implement the core math logic that checks if a neuron’s potential exceeds its threshold, triggers a "spike," and updates the potentials of connected downstream neurons.

[x] 13. **Climbing Fiber Algorithm:** Within `SimulationService`, implement the error-correction logic. Create a method that compares the Purkinje output to the target signal and adjusts synaptic weights based on biological supervised learning rules.

[x] 14. **Simulation Ticker Provider:** Create a `SimulationNotifier` using Riverpod in `/providers`. Use a `Ticker` or `Timer.periodic` to trigger the simulation logic 60 times per second and notify the UI of state changes.

[x] 15. **Neural Canvas Painter:** In `/widgets`, implement a `NeuralCanvas` using `CustomPainter`. It should take the current `SimulationState` and draw neurons as circles and synapses as lines, with colors changing based on spike activity.

[x] 16. **Interactive Viewer Implementation:** Wrap the `NeuralCanvas` in an `InteractiveViewer` within the `HomeScreen`. Configure it to allow users to pinch-to-zoom and pan across the high-resolution neural map.

[x] 17. **Input Signal Provider:** Create a provider in `/providers` that generates a variety of target signals (e.g., Sine wave, Step function). This acts as the "training data" for the neural network.

[x] 18. **Real-Time Signal Plotter:** Build a `SignalPlotter` widget in `/widgets` that graphs the target input wave against the actual output from the simulation to visualize learning progress.

**Phase 2.5: Actor-Critic RL Refactor (Kuriyama et al. 2025)**

[x] 19. **RL Data Models Update:** Read `lib/models/neuron.dart` and `lib/models/synapse.dart`. I am refactoring this project to an Actor-Critic Reinforcement Learning model. 
1. In `Neuron`, add a `double decayRate` (default 0.1) for Leaky Integrate-and-Fire dynamics, and a `String? actionGroup` to group motor cells. 
2. In `Synapse`, add a `double eligibilityTrace` (default 0.0) and a `String targetType` (e.g., 'PC' or 'SC'). 
Ensure both classes remain completely immutable, update their `copyWith`, `toJson`, and `fromJson` methods, and output the complete code for both files.

[ ] 20. **Leaky Integrate-and-Fire (LIF) Engine:** Read `lib/services/simulation_service.dart`. Update the `calculateNextState` method to support Continuous-Time RL. 
1. Instead of simply maintaining potential, non-spiking neurons must multiply their current potential by `(1.0 - neuron.decayRate)` before adding new incoming potential. 
2. Update synapse eligibility traces: multiply all current traces by a decay factor (e.g., 0.95). If the synapse's `sourceId` just spiked, add 1.0 to its trace. Output the updated method.

[ ] 21. **Actor-Critic Learning Rule:** Read `lib/services/simulation_service.dart`. Delete the `adjustWeights` method. Write a new method `SimulationState adjustWeightsRL(SimulationState currentState, {required double climbingFiberPunishment})`. 
1. Calculate `predictedPunishment` by summing the potential of all 'SC' (Stellate Cell) neurons. 
2. Calculate `tdError = climbingFiberPunishment - predictedPunishment`. 
3. Loop through synapses. If `eligibilityTrace < 0.01`, skip. 
4. If target is 'SC' (Critic), `newWeight += learningRate * tdError * eligibilityTrace`. 
5. If target is 'PC' (Actor), `newWeight -= learningRate * tdError * eligibilityTrace`. Clamp weights between 0.0 and 1.0. Output the updated method.

[ ] 22. **DCN Action Selection:** Read `lib/services/simulation_service.dart`. Add a new method `String getExecutedAction(SimulationState currentState)`. 
Filter the state for 'DCN' (Deep Cerebellar Nuclei) neurons. Find the DCN neuron with the highest `currentPotential` (using argmax). Return its `actionGroup` string (e.g., 'antiopen' or 'anticlose'). If no DCN cells exist or potentials are tied at 0, return 'none'. Output the new method.

[ ] 23. **Environment Provider Refactor:** Read `lib/providers/signal_provider.dart` and `lib/providers/simulation_provider.dart`. We are replacing the supervised "target wave" with an episodic RL environment. 
Rename/Refactor the signal provider to an `environmentProvider` using Riverpod. It should hold state for an `episodeNumber` and `currentStep` (0 to 1000ms). It should expose a method to get the current state vector for the Parallel Fibers, and a method `double getClimbingFiberSignal()` that returns a negative punishment (e.g., -1.0) only if the wrong action is taken at step 500. Output the complete new provider code.

[ ] 24. **UI Canvas & Plotter Updates:** Read `lib/widgets/neural_canvas.dart` and `lib/widgets/signal_plotter.dart`. 
1. Update the `CustomPainter` to assign specific colors and vertical layers to the new cell types: SC (Critic), BC (Inhibitor), and DCN (Output). 
2. Update the `SignalPlotter` to stop comparing "Target vs Output". Instead, plot the SC group's `predictedPunishment` against the actual `climbingFiberPunishment` over the 1000ms episode to visualize the Critic's learning. Output the updated widget code.

**Phase 3: Milestone 2 - Full Integration (Auth & Database)**

[ ] 19. **Authentication Service:** Implement `AuthService` in `/services` using Firebase Authentication. Include methods for Email/Password sign-up, login, and sign-out.

[ ] 20. **Google Sign-In Integration:** Expand the `AuthService` to include Google Sign-In as an advanced authentication provider.

[ ] 21. **The Auth Gate:** Create an `AuthGate` widget in `/widgets` that listens to the Firebase Auth state stream. Show the `LoginScreen` if the user is unauthenticated, otherwise show the `HomeScreen`.

[ ] 22. **Authentication UI:** Create a professional `LoginScreen` and `RegistrationScreen` in `/screens` that use the custom `ThemeData` and handle loading/error states.

[ ] 23. **Firestore Database Service:** Build a `DatabaseService` in `/services` to handle cloud persistence. Implement a method to convert the current `SimulationState` into a JSON map for storage.

[ ] 24. **Research Vault CRUD:** Implement methods in `DatabaseService` to save "Brain State" snapshots to Firestore and fetch a list of previous simulation sessions.

[ ] 25. **Cloud Gallery UI:** Create a `GalleryScreen` in `/screens` using a Riverpod `StreamProvider` to display the user's saved simulations from the cloud in real-time.

[ ] 26. **Cloud Loading Logic:** Implement a feature to "Load" a snapshot from the Gallery, which replaces the local simulation weights and connections with the data retrieved from Firestore.

**Development Rules**
1. [x]**One Prompt = One Commit:** Always commit the current code and refer to the Prompt # in the commit message before adding a new feature.
2. [x]**No Magic Code:** I am strictly responsible for understanding every line of code generated and must be able to explain it during weekly check-ins.
3. [x]**Refactor Early:** Any file exceeding 200 lines must be broken down into smaller, isolated custom widgets.
4. [ ]**Test-Driven Execution:** Create and pass a unit or widget test for the specific feature generated in each prompt before moving on to the next one.