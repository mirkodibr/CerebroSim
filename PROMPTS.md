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

[ ] 13. **Climbing Fiber Algorithm:** Within `SimulationService`, implement the error-correction logic. Create a method that compares the Purkinje output to the target signal and adjusts synaptic weights based on biological supervised learning rules.

[ ] 14. **Simulation Ticker Provider:** Create a `SimulationNotifier` using Riverpod in `/providers`. Use a `Ticker` or `Timer.periodic` to trigger the simulation logic 60 times per second and notify the UI of state changes.

[ ] 15. **Neural Canvas Painter:** In `/widgets`, implement a `NeuralCanvas` using `CustomPainter`. It should take the current `SimulationState` and draw neurons as circles and synapses as lines, with colors changing based on spike activity.

[ ] 16. **Interactive Viewer Implementation:** Wrap the `NeuralCanvas` in an `InteractiveViewer` within the `HomeScreen`. Configure it to allow users to pinch-to-zoom and pan across the high-resolution neural map.

[ ] 17. **Input Signal Provider:** Create a provider in `/providers` that generates a variety of target signals (e.g., Sine wave, Step function). This acts as the "training data" for the neural network.

[ ] 18. **Real-Time Signal Plotter:** Build a `SignalPlotter` widget in `/widgets` that graphs the target input wave against the actual output from the simulation to visualize learning progress.

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