# CerebroSim Development Log

## Development Rules
* **One Prompt = One Commit:** Always commit the current code and refer to the Prompt # in the commit message before adding a new feature.
* **No Magic Code:** I am strictly responsible for understanding every line of code generated and must be able to explain it during weekly check-ins.
* **Refactor Early:** Any file exceeding 200 lines must be broken down into smaller, isolated custom widgets.
* **Test-Driven Execution:** Create and pass a unit or widget test for the specific feature generated in each prompt before moving on to the next one.

---

## Phase 0: Project Reset & Model Rebuild
*These prompts clean up the existing codebase so the new architecture has a solid foundation. The old Neuron/Synapse models are replaced with the new architecture before any new feature is built. Do not skip this phase.*

- [x] **1. Model Rename — NeuronModel:** Delete `lib/models/neuron.dart`. Create `lib/models/neuron_model.dart` with an `@immutable` class `NeuronModel`. Fields: `String id`, `String cellType` (one of 'GC', 'PC', 'BC', 'DCN', 'CF'), `double membranePotential` (starts 0.0), `double restingPotential` (0.0), `double threshold` (1.0), `double decayRate` (0.1), `double eligibilityTrace` (0.0), `bool isInhibitory`, `bool isFiring`. Include a const constructor, `copyWith`, and a factory `NeuronModel.initial({required String id, required String cellType})` that sets `isInhibitory: true` for PC and BC types. No Flutter imports. After creating, search all files for imports of the old `neuron.dart` and update them.
- [x] **2. Model Rename — SynapseModel:** Delete `lib/models/synapse.dart`. Create `lib/models/synapse_model.dart` with an `@immutable` class `SynapseModel`. Fields: `String id` (e.g. 'GC_01->PC_01'), `String fromNeuronId`, `String toNeuronId`, `double weight`, `double eligibility` (starts 0.0), `bool isInhibitory`. Include a const constructor, `copyWith`, and a factory `SynapseModel.initial({required String fromId, required String toId, required bool isInhibitory})` that sets weight to `-0.1` if inhibitory, `+0.1` otherwise. No Flutter imports. After creating, update all imports of the old `synapse.dart`.
- [x] **3. Simulation Constants:** Create `lib/models/simulation_constants.dart`. Define a `SimulationConstants` class with static const values: `kDefaultLearningRate = 0.01`, `kDefaultDecayRate = 0.1`, `kDefaultThreshold = 1.0`, `kTickRateHz = 60`, `kDefaultHeadVelAmplitude = 40.0`, `kDefaultVorFrequencyHz = 1.0`, `kHealthyVorGain = 1.0`, `kAtaxiaVorGain = 0.4`. No constructor needed — all values are static.
- [x] **4. SimulationState Rebuild:** Delete the old `SimulationState`. Create `lib/models/simulation_state.dart` with an `@immutable` class `SimulationState`. Fields: `List<NeuronModel> neurons`, `List<SynapseModel> synapses`, `double criticPrediction`, `double tdError`, `double climbingFiberSignal`, `double rollingGainRatio`, `int episodeStep`, `int episodeCount`, `bool isRunning`. Include const constructor, `copyWith`, and a factory `SimulationState.initial()` that creates 5 neurons (one each of GC, PC, BC, DCN, CF) and 4 synapses (GC->PC excitatory, GC->BC excitatory, BC->PC inhibitory, PC->DCN inhibitory), all doubles at `0.0`, counts at `0`, `isRunning: false`. Run `flutter analyze` and fix all errors before continuing.

---

## Phase 1: Project Setup & Core Infrastructure

- [x] **5. Dependency Injection:** Add `flutter_riverpod`, `firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in`, `shared_preferences`, and `google_fonts` to `pubspec.yaml`. Run `flutter pub get`. Ensure all dependencies are compatible with the latest stable Flutter version.
- [x] **6. Directory Architecture:** Create the following directory structure within the `lib/` folder: `/models`, `/screens`, `/widgets`, `/services`, and `/providers`. Add a placeholder `.gitkeep` file in each to ensure they are tracked by Git.
- [x] **7. Async Initialization:** Update `main.dart` to make `main()` async. Add `WidgetsFlutterBinding.ensureInitialized()` and `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` before `runApp`. The app must not launch until Firebase is ready.
- [x] **8. Root ProviderScope:** In `main.dart`, wrap the root `MaterialApp` in a `ProviderScope`. This is the required step to enable Riverpod state management throughout the entire application.

---

## Phase 2: Theming & Navigation Shell

- [x] **9. Dual Theme System:** Delete `lib/theme.dart`. Create `lib/services/theme_service.dart` with a `ThemeService` class containing two static getters. 
  * `cyberLabTheme`: dark mode, `scaffoldBackgroundColor: Color(0xFF121212)`, `ColorScheme.dark` with primary `Color(0xFF00FFFF)`, secondary `Color(0xFF8A2BE2)`, error `Color(0xFFFF4444)`, surface `Color(0xFF1E1E1E)`, `textTheme` using `GoogleFonts.spaceMonoTextTheme`. 
  * `presentationTheme`: light mode, `scaffoldBackgroundColor: Color(0xFFFAFAFA)`, `ColorScheme.light` with primary `Color(0xFF185FA5)`, secondary `Color(0xFF1D9E75)`, `textTheme` using `GoogleFonts.interTextTheme`. 
  * After creating, search for any import of the old `lib/theme.dart` and update them.
- [x] **10. Theme Persistence:** Create `lib/providers/theme_provider.dart`. First, add a `sharedPreferencesProvider` using `FutureProvider<SharedPreferences>` that calls `SharedPreferences.getInstance()`. Then create a `ThemeNotifier` extending `Notifier<ThemeMode>`. In `build()`, read the key `'theme_preference'` from SharedPreferences — return `ThemeMode.dark` if null or 'dark', `ThemeMode.light` if 'light'. Add a `toggle()` method that flips the state and persists the new value. Expose as `themeNotifierProvider`.
- [x] **11. App Shell & Profile Screen:** Create `lib/screens/app_shell.dart` as a `ConsumerStatefulWidget` with a `BottomNavigationBar` and `IndexedStack`. Three tabs: Simulate (`Icons.biotech`), Vault (`Icons.science`), Profile (`Icons.person`). Use `Theme.of(context)` colors only — no hardcoded colors. Create `lib/screens/profile_screen.dart` as a `ConsumerWidget` showing the signed-in user's email, a `SwitchListTile` for theme toggle (reads/writes `themeNotifierProvider`), and a sign-out `ListTile`. Update `MaterialApp` in `main.dart` to use `theme: ThemeService.presentationTheme`, `darkTheme: ThemeService.cyberLabTheme`, and `themeMode: ref.watch(themeNotifierProvider)`.

---

## Phase 3: Authentication
*Auth must be completed before the Vault (Phase 7) since every Firestore document is scoped to an authenticated user.*

- [x] **12. Authentication Service:** Create `lib/services/auth_service.dart`. Rules: no Flutter imports, no `BuildContext`, do not catch exceptions — let them propagate. Expose exactly four methods: `Future<UserCredential> signInWithEmail(String email, String password)`, `Future<UserCredential> registerWithEmail(String email, String password)`, `Future<UserCredential> signInWithGoogle()` (throws `FirebaseAuthException(code: 'sign-in-cancelled')` if the user cancels), `Future<void> signOut()` (calls both `GoogleSignIn().signOut()` and `FirebaseAuth.instance.signOut()`).
- [x] **13. Auth State Provider:** Create `lib/providers/auth_provider.dart`. Create an `authServiceProvider` using `Provider<AuthService>`. Create `AuthNotifier` extending `AsyncNotifier<User?>`. In `build()`, subscribe to `FirebaseAuth.instance.authStateChanges()` using a `StreamSubscription` cancelled via `ref.onDispose`. Set initial state to `AsyncData(FirebaseAuth.instance.currentUser)`. Expose `signIn`, `register`, `signInWithGoogle`, and `signOut` methods — each sets `AsyncLoading()` before the call and `AsyncError(e, s)` on `FirebaseAuthException`. Expose as `authProvider`.
- [x] **14. Login Screen:** Create `lib/screens/login_screen.dart` as a `ConsumerStatefulWidget`. Include email and password `TextEditingController`s (disposed in `dispose()`), a `Form` with a `GlobalKey<FormState>`, email validator (non-empty, contains `@`), password validator (non-empty, length ≥ 6). Sign-in button: disabled with `CircularProgressIndicator` when `AsyncLoading`, calls `ref.read(authProvider.notifier).signIn(email, password)` on tap. Google sign-in `OutlinedButton`: same loading logic, calls `signInWithGoogle()`. Text button to navigate to `RegisterScreen`. Use `ref.listen` on `authProvider`: `AsyncError` shows a `SnackBar`, `AsyncData` with non-null user navigates to `AppShell` using `Navigator.pushReplacement`. No hardcoded colors.
- [x] **15. Register Screen:** Create `lib/screens/register_screen.dart` following the same pattern as `LoginScreen`. Three fields: email, password, confirmPassword (validator checks value equals `_passwordController.text`). Action button calls `register()`. No Google sign-in button. Bottom `TextButton` navigates back with `Navigator.pop`.
- [x] **16. Auth Route Guard:** Update `main.dart` so `CerebroSimApp` is a `ConsumerWidget` watching `authProvider`. `AsyncLoading` → centered `CircularProgressIndicator`. `AsyncData` with null user → `LoginScreen`. `AsyncData` with non-null user → `AppShell`. `AsyncError` → `LoginScreen`. Run `flutter analyze` and `flutter test`. Describe the manual test steps to confirm sign-in, sign-out, and persistence across restarts all work.
- [x] **16.5. Auth Logic Audit — Sign-Out Verification:** Perform a comprehensive check of the sign-out flow to ensure session persistence is properly cleared. 1. Verify that `AuthService.signOut()` in `lib/services/auth_service.dart` calls both `GoogleSignIn().signOut()` and `FirebaseAuth.instance.signOut()`. 2. Ensure `AuthNotifier.signOut()` in `lib/providers/auth_provider.dart` sets the state to `AsyncLoading()` before execution. 3. Create a test case in `test/services/auth_service_test.dart` to confirm that after `signOut()` is called, the `authStateChanges()` stream emits `null`. 4. If the user remains logged in or the UI does not redirect, refactor the `main.dart` route guard to explicitly trigger a `Navigator.pushAndRemoveUntil` to clear the navigation stack.
---

## Phase 4: Simulation Engine
*Build the engine in pure Dart with unit tests before adding any UI. Do not proceed to Phase 5 until flutter test passes completely.*

- [x] **17. EnvironmentStep Model:** Ensure `lib/models/environment.dart` exists with `@immutable` class `EnvironmentStep` containing `List<double> stateVector`, `double punishment`, `bool isEpisodeEnd`, and a const constructor. Also create `lib/models/cerebellar_task.dart` with `enum CerebellarTask { eyeblink, sineWave, vor }`. No Flutter imports in either file.
- [x] **18. SimulationEngine Skeleton:** Delete `lib/services/simulation_service.dart`. Create `lib/services/simulation_engine.dart`. Rules: no Flutter imports, no Riverpod, pure Dart. The class `SimulationEngine` must have: a public `SimulationState initialState()` that returns `SimulationState.initial()`, a public `SimulationState tick(SimulationState current, EnvironmentStep env, double dt)` that returns current unchanged for now (stub), and four private stubs returning 0.0 or unchanged input: `_lifUpdate`, `_tdError`, `_updateWeights`, `_eligibilityUpdate`. Run `flutter analyze` after.
- [x] **19. LIF Update Method:** In `lib/services/simulation_engine.dart`, implement `_lifUpdate(NeuronModel n, double inputCurrent)` using the formula `V(t+1) = V(t) * (1 - decayRate) + inputCurrent`. Implement `_eligibilityUpdate(double currentTrace, double preSynapticActivity, double decayRate)` using `e(t+1) = e(t) * (1 - decayRate) + preSynapticActivity`. Write unit tests in `test/simulation_engine_test.dart`: given membranePotential=0.5, decayRate=0.1, inputCurrent=0.0 → expect 0.45; given membranePotential=0.0, inputCurrent=0.3 → expect 0.27. Run `flutter test` — must pass before continuing.
- [x] **20. TD Error Method:** In `lib/services/simulation_engine.dart`, implement `_tdError(double reward, double vNext, double vCurrent, {double gamma = 0.95})` using `delta = r + gamma * V(t+1) - V(t)`. Write unit tests: reward=0.0, vNext=0.5, vCurrent=0.3, gamma=0.95 → expect 0.175; reward=1.0, vNext=0.0, vCurrent=0.0 → expect 1.0; reward=0.0, vNext=0.0, vCurrent=0.5 → expect -0.5. Run `flutter test` — must pass.
- [x] **21. Weight Update Method:** In `lib/services/simulation_engine.dart`, implement `_updateWeights(List<SynapseModel> synapses, List<NeuronModel> neurons, double tdError, double learningRate)`. For each synapse: find the pre-synaptic neuron, apply `sign = isInhibitory ? -1.0 : 1.0`, compute `deltaW = sign * learningRate * tdError * preNeuron.eligibilityTrace`, clamp new weight to [-2.0, 2.0]. Write unit tests: excitatory synapse weight=0.1, eligibilityTrace=0.5, tdError=0.2, learningRate=0.01 → expect ≈ 0.101; inhibitory synapse → expect ≈ -0.101; weight at 1.99 with large positive tdError → expect clamped to 2.0. Run `flutter test` — must pass.
- [x] **22. Tick Assembly:** In `lib/services/simulation_engine.dart`, implement the full `tick()` method. 
  * Step 1: compute input currents — GC receives `stateVector[0]`, CF receives `env.punishment`, all others receive the weighted sum of incoming synapses (`weight * preNeuron.membranePotential`). DCN additionally receives a baseline drive of +0.5 (biological hotfix — prevents inhibition collapse). 
  * Step 2: run `_lifUpdate` for each neuron, mark `isFiring: true` if new potential ≥ threshold, reset to `restingPotential` if firing, update `eligibilityTrace` via `_eligibilityUpdate`. 
  * Step 3: compute tdError using DCN's new potential as vNext and `reward = 1.0 - env.punishment`. 
  * Step 4: call `_updateWeights`. 
  * Step 5: return new `SimulationState` with all updated values, incrementing `episodeStep` or resetting on `isEpisodeEnd`. Write unit tests: tick does not crash and episodeStep increments; isEpisodeEnd: true resets episodeStep to 0 and increments episodeCount. Run `flutter test` — all tests must pass.
- [x] **23. SimulationNotifier:** Create `lib/providers/simulation_provider.dart`. `SimulationNotifier` extends `Notifier<SimulationState>`. `build()` returns `_engine.initialState()`. Implement `startSimulation()` (starts a `Timer.periodic` at `kTickRateHz`, sets `isRunning: true`), `stopSimulation()` (cancels timer, sets `isRunning: false`), `resetEpisode()` (stops and resets to `initialState()`), `loadSnapshot(List<double> weights)` (restores synaptic weights if length matches), and a private `_tick()` that uses a placeholder `EnvironmentStep` for now. Override `dispose()` to cancel the timer. Expose as `simulationProvider`. Run `flutter analyze` and `flutter test`.

---

## Phase 5: Neural Canvas Visualisation

- [x] **24. Neural Canvas Painter:** *(Originally Prompt 15 — rebuilding against new models.)* Delete the old `neural_canvas.dart`. Create `lib/widgets/neural_canvas.dart` as a `ConsumerStatefulWidget` using `SingleTickerProviderStateMixin`. The `AnimationController` ticks continuously and calls `setState` each tick; dispose it in `dispose()`. Wrap an `InteractiveViewer` (minScale 0.5, maxScale 3.0) around a `CustomPaint` using `NeuralCanvasPainter(state: ref.watch(simulationProvider), repaint: _animationController)`. Extract `NeuralCanvasPainter` as a separate class in the same file.
- [x] **25. Canvas Layer Rendering:** *(Originally Prompt 29 — rebuilt against NeuronModel.)* In `NeuralCanvasPainter.paint()`, draw three horizontal background bands: top third `Color(0xFF0A1A2A)` labeled 'Molecular layer', middle third `Color(0xFF0F0A1A)` labeled 'Purkinje layer', bottom third `Color(0xFF0A1A0A)` labeled 'Granular layer'. Position neurons at fixed normalised coordinates: CF (0.15, 0.15), GC (0.30, 0.80), BC (0.55, 0.55), PC (0.70, 0.50), DCN (0.85, 0.75). Draw synapses before neurons: excitatory `Color(0xFF00FFFF)` opacity 0.4, inhibitory `Color(0xFFFF4444)` opacity 0.6 dashed, line width proportional to `weight.abs()` clamped 0.5–3.0. Draw each neuron as a filled circle radius 12.0 with type-specific colors: GC amber #EF9F27, PC purple #8A2BE2, BC coral #D85A30, DCN teal #1D9E75, CF red #E24B4A. Draw a white outer ring (stroke, radius 20.0) if `neuron.isFiring`. Draw cellType label below each circle.
- [x] **26. Tap-to-Inspect:** Add `GestureDetector.onTapDown` to `NeuralCanvasWidget`. On tap, find the nearest neuron within 20px of the tap position. If found, call `showModalBottomSheet` with a new `NeuronDetailSheet` widget (create in `lib/widgets/neuron_detail_sheet.dart`). The sheet shows cellType as a large title, an 'Inhibitory' or 'Excitatory' chip, and four data rows: `membranePotential`, `eligibilityTrace`, `threshold`, and firing status ('FIRING' in red or 'resting' in muted grey).

---

## Phase 6: Task Environments

- [x] **27. Environment Provider Refactor:** *(Originally Prompt 23/25 — rebuilt to use CerebellarEnvironment interface.)* Create `lib/models/environment.dart` with the abstract class `CerebellarEnvironment` defining `String get taskName`, `double get traceDecayMs`, `EnvironmentStep step(SimulationState state, double dt)`, and `void reset()`. This is the interface all three task environments will implement.
- [x] **28. Eyeblink Conditioning Environment:** *(Originally Prompt 25 — rebuilt with continuous time and correct interface.)* Create `lib/services/eyeblink_environment.dart` implementing `CerebellarEnvironment`. CS active for 250ms, US fires at 250ms for 50ms, trial duration 1.0s. Punishment is 1.0 if US fires and no DCN spike was produced during the CS window, 0.0 otherwise. `stateVector: [csActive ? 1.0 : 0.0, t / trialDuration, blinkProduced ? 1.0 : 0.0]`. `traceDecayMs: 300.0`. Call `reset()` automatically at episode end.
- [x] **29. Sine Wave Tracking Environment:** *(Originally Prompt 27 — rebuilt with directional punishment fix baked in.)* Create `lib/services/sine_wave_environment.dart` implementing `CerebellarEnvironment`. Target: `amplitude * sin(2π * frequencyHz * t)`. Punishment is only applied when the DCN output is moving in the wrong direction relative to the wave slope — compute `isWaveMovingUp = cos(2π * f * t) > 0` and compare to output direction. This prevents the agent-freezing bug from the original implementation. `traceDecayMs: 100.0`.
- [x] **30. VOR Adaptation Environment:** *(New — never existed.)* Create `lib/models/vor_config.dart` with `@immutable` class `VorConfig` holding `targetGain` (default 1.0), `amplitude` (default 40.0), `frequency` (default 1.0), plus const constructor and `copyWith`. Create `lib/services/vor_environment.dart` implementing `CerebellarEnvironment`. Head velocity: `amplitude * sin(2π * frequency * t)`. Target eye velocity: `-headVel * targetGain`. Punishment: `|imageSlip| / amplitude` normalised 0.0–1.0. `stateVector: [normHeadVel, normEyeVel, gainRatio, normSlip]`. `traceDecayMs: 50.0`. Call `reset()` at episode end.
- [x] **31. EnvironmentProvider:** Create `lib/providers/environment_provider.dart`. Create `VorConfigNotifier` extending `Notifier<VorConfig>` with an `update(VorConfig c)` method, exposed as `vorConfigProvider`. Create `EnvironmentNotifier` extending `Notifier<CerebellarTask>` with a `selectTask(CerebellarTask task)` method that resets the environment and calls `simulationProvider.notifier.resetEpisode()`, a `step(SimulationState s)` method delegating to the active environment, and a private `_buildEnv(CerebellarTask t)` switch that constructs the correct environment. Update `SimulationNotifier._tick()` in `simulation_provider.dart` to call `ref.read(environmentProvider.notifier).step(state)` instead of the placeholder. Run `flutter analyze` and `flutter test`.
- [x] **32. Signal Plotter Rebuild:** *(Originally Prompt 30 — rebuilt to plot Critic vs actual vs VOR gain.)* Create `lib/models/plot_point.dart` with `@immutable` class `PlotPoint` holding `criticPrediction`, `actualSignal`, `gainRatio` (default 0.0). Create a `plotBufferProvider` as a `StateProvider<List<PlotPoint>>`. Delete the old `signal_plotter.dart`. Create `lib/widgets/signal_plotter.dart` as a `ConsumerWidget` that appends a new `PlotPoint` on each build (keep last 200), then renders a `CustomPaint` with `SignalPlotterPainter`. The painter draws three lines: `criticPrediction` in cyan #00FFFF, `actualSignal` in amber #EF9F27, `gainRatio` in purple #8A2BE2 (only when VOR task is active). Include a legend. If the painter class exceeds 80 lines, extract it to `lib/widgets/signal_plotter_painter.dart`.
- [x] **33. Task Selector & Simulate Screen:** Create `lib/widgets/task_selector.dart` as a `ConsumerWidget` with a `SegmentedButton<CerebellarTask>` for the three tasks. If the simulation is running when the user switches, show an `AlertDialog` confirming the reset. When the VOR task is selected, show `VorConfigPanel` (same file) with three sliders for targetGain, amplitude, and frequency updating `vorConfigProvider`. Show a status label: 'Simulating cerebellar ataxia' if gain < 0.6, 'Simulating gain-up adaptation' if gain > 1.4, otherwise 'Healthy VOR baseline'. Replace the `SimulateScreen` stub in `lib/screens/simulate_screen.dart` with a real `ConsumerWidget`: `AppBar` with play/stop and save `IconButton`s, body `Column` with `TaskSelectorWidget`, `Expanded` `NeuralCanvasWidget`, `SizedBox(height: 180, child: SignalPlotterWidget)`. Wire into AppShell index 0.

---

## Phase 7: Guided Onboarding
*New feature — never existed in the previous session.*

- [x] **34. Prefs Service & Onboarding Flag:** Create `lib/services/prefs_service.dart` with a `PrefsService` class exposing `Future<bool> isOnboardingComplete()`, `Future<void> setOnboardingComplete()`, and `Future<void> clearOnboarding()`. Create a `prefsServiceProvider` using `Provider<PrefsService>`. Create an `onboardingCompleteProvider` using `FutureProvider<bool>` that calls `isOnboardingComplete()`. Update the route guard in `main.dart`: after confirming the user is signed in, check `onboardingCompleteProvider` — if false, show `OnboardingScreen` (stub for now); if true, show `AppShell`.
- [x] **35. Onboarding Screen — Step 1 (Watch Mode):** Create `lib/screens/onboarding_screen.dart` as a `ConsumerStatefulWidget` with a `PageController` and `PageView`. Create `lib/widgets/onboarding/watch_mode_step.dart` (`OnboardingStep1`): `initState` starts the simulation automatically; `dispose` stops it. Shows `NeuralCanvasWidget` in read-only mode with overlay text: 'Your cerebellum learns by trying and failing. Watch the network attempt to predict the error signal.' Auto-advances after 30 seconds via a `Timer`. A 'I see it →' button also advances the page.
- [x] **36. Onboarding Screen — Step 2 (Controls):** Create `lib/widgets/onboarding/control_step.dart` (`OnboardingStep2`). Shows `SignalPlotterWidget` and a single `Slider` for learning rate (min 0.001, max 0.1). The slider updates a `learningRateProvider` (`StateProvider<double>`). The 'Next →' button is disabled until the user has interacted with the slider at least once.
- [x] **37. Onboarding Screen — Step 3 (Explore):** Create `lib/widgets/onboarding/explore_step.dart` (`OnboardingStep3`). Shows the full `NeuralCanvasWidget` with tap-to-inspect enabled and `TaskSelectorWidget`. Overlay text: 'Tap any cell to learn what it does.' A 'Start researching →' button calls `setOnboardingComplete()` and navigates to `AppShell`. Add a 'Skip' button to the `AppBar` of `OnboardingScreen` on all pages that does the same.
- [x] **37.5. Onboarding Navigation — Bidirectional Flow:** Update `lib/screens/onboarding_screen.dart` to support moving backward through steps. 1. In `_OnboardingScreenState`, add an `int _currentPage = 0` variable. Update this variable using the `onPageChanged` callback in the `PageView`. 2. Implement a `_onBack()` method that calls `_pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)`. 3. Add a `TextButton` or `IconButton` (using `Icons.arrow_back`) to the UI that triggers `_onBack()`. Use a `Visibility` widget to hide this button when `_currentPage == 0`.
- [x] **38. Cell Type Tooltips:** Create `lib/models/cell_type_descriptions.dart` with a `const Map<String, String> kCellTypeDescriptions` mapping each cellType to a one-sentence plain-English description: GC — granule cell receives and relays sensory signals; PC — Purkinje cell controls the degree of movement correction; BC — basket cell suppresses neighbouring Purkinje cells to sharpen signals; DCN — deep cerebellar nucleus sends correction signals to the motor system; CF — climbing fibre carries error signals from the inferior olive. Update `NeuronDetailSheet` to show the description below the data rows.

---

## Phase 8: Research Vault
*Requires Phase 3 (Auth) to be complete. Every Firestore document is scoped to the authenticated user's UID.*

- [x] **39. Experiment Snapshot Model:** Create `lib/models/experiment_snapshot.dart` with `@immutable` class `ExperimentSnapshot`. Fields: `String id`, `String userId`, `String userEmail`, `String taskName`, `double finalErrorRate`, `double? finalVorGain`, `List<double> synapticWeights`, `int episodeCount`, `bool isPublic`, `String title`, `DateTime createdAt`. Implement `copyWith`, `Map<String, dynamic> toFirestore()` (stores DateTime as Timestamp, List<double> directly), factory `ExperimentSnapshot.fromFirestore(DocumentSnapshot doc)` (handles missing fields gracefully), and factory `ExperimentSnapshot.fromSimulation({...})` that builds a snapshot from the current `SimulationState`. No Flutter widgets.
- [x] **40. Database Service:** Create `lib/services/database_service.dart`. Methods: `Future<void> saveSnapshot(ExperimentSnapshot snap)` — writes to `users/{uid}/snapshots/` and also to `public_snapshots/` if `isPublic` is true; `Stream<List<ExperimentSnapshot>> watchUserSnapshots(String uid)` — real-time stream ordered by createdAt descending; `Future<List<ExperimentSnapshot>> fetchPublicGallery({int limit = 50})` — queries `public_snapshots` ordered by createdAt descending. Add `.timeout(Duration(seconds: 10))` to all Future calls. No Flutter widgets, no `BuildContext`.
- [x] **41. Vault Notifier:** Create `lib/providers/vault_provider.dart`. `VaultNotifier` extends `AsyncNotifier<List<ExperimentSnapshot>>`. `build()` subscribes to `watchUserSnapshots(uid)` and returns the first emission; subsequent stream events update state via a listener. Implement `Future<void> saveSnapshot({...})` that sets `AsyncLoading`, calls `DatabaseService.saveSnapshot`, and handles errors by setting `AsyncError` then restoring the previous data state. Create a `publicGalleryProvider` using `FutureProvider<List<ExperimentSnapshot>>`.
- [x] **42. Vault Screen:** Create `lib/screens/vault_screen.dart` as a `ConsumerWidget` with a `DefaultTabController` and two tabs: 'My Experiments' and 'Gallery'. Each tab uses a `ListView.builder` over its respective provider's `AsyncValue`, with loading showing a `CircularProgressIndicator`, error showing the error message, and data rendering `SnapshotCard` widgets. `SnapshotCard` (create in the same file or `lib/widgets/snapshot_card.dart`) shows: title, task name chip, episode count, final error rate, date, and a public badge if applicable. Tapping a card calls `ref.read(simulationProvider.notifier).loadSnapshot(snapshot.synapticWeights)` and navigates to the Simulate tab. Wire `VaultScreen` into AppShell index 1.
- [x] **43. Save Dialog in Simulate Screen:** Add the save flow to `lib/screens/simulate_screen.dart`. The save `IconButton` in the `AppBar` opens a `showModalBottomSheet` with a `TextFormField` for the experiment title (required, min 3 chars), a `SwitchListTile` for 'Share publicly', and a 'Save experiment' `ElevatedButton`. On confirm: validate the title, call `ref.read(vaultProvider.notifier).saveSnapshot(...)` with the current `SimulationState`, show a `SnackBar` on success reading 'Experiment saved!', and close the sheet. Add Firestore security rules to a `FIRESTORE_RULES.md` file at the project root: user documents writeable only by the owning UID; `public_snapshots` readable by all authenticated users, not directly writeable by clients.

---

## Phase 9: Polish & Submission Prep

- [x] **44. Error Handling Audit:** Review every async call in every service and provider. Each one must have a `try/catch` that either sets `state = AsyncError(e, s)` on the notifier or shows a user-visible `SnackBar`. Special cases: `signInWithGoogle` when user cancels (not an error — handle gracefully with no snackbar); `DatabaseService.saveSnapshot` when offline (catch TimeoutException); `VaultNotifier.saveSnapshot` must restore the previous data state after an error, not leave the vault in a permanent loading state.
- [x] **45. Loading States:** Find every place where an `AsyncNotifier` or `FutureProvider` is watched without a loading handler in `.when(...)`. Add a `CircularProgressIndicator()` to each. Add shimmer loading to the `VaultScreen` list while snapshots are fetching (use the `shimmer` package or a Shimmer-style placeholder built with `Container` + `AnimatedOpacity`).
- [x] **46. File Length & Const Audit:** Run `find lib/ -name '*.dart' | xargs wc -l | sort -n | tail -20`. Any file over 200 lines must be split before submission. Run a search for widget constructors missing `const` and add it wherever possible. Replace all `print()` calls with `debugPrint()`.
- [x] **47. PROMPTS.md & Git Audit:** Every prompt above must have a corresponding commit in the Git log referencing its prompt number. Run `git log --oneline` and verify. If any large gap commits exist ('fixed everything'), use `git rebase -i` to break them down. Run the full manual test from the submission checklist: fresh install → onboarding → register → eyeblink 10 episodes → switch to VOR (ataxia mode) → run 10 episodes → save public snapshot → sign out → sign in with Google → verify snapshot in gallery → load it → confirm weights restored.

---

## Phase 10: Architectural Hardening & Correctness
*This phase addresses critical synchronization, parameter injection, and data safety issues identified during the integration of the simulation engine and the UI.*

- [x] **48. Plotter Synchronization & Buffer Management:** Refactor `lib/widgets/signal_plotter.dart` and `lib/providers/simulation_provider.dart`. 1. Remove all logic that appends `PlotPoint` inside the `build()` method of `SignalPlotter`. 2. In `SimulationNotifier`, update the `_tick()` method to access the `plotBufferProvider.notifier` and append a new `PlotPoint` containing the current `criticPrediction`, `climbingFiberSignal`, and `rollingGainRatio`. 3. Ensure the buffer is capped at 200 points using `state = [...state.skip(state.length > 200 ? 1 : 0), newPoint]`. 4. Verify that UI events (theme toggles, keyboard) no longer pollute the buffer; plot points must only generate when `isRunning` is true.

- [x] **49. Dynamic Parameter Injection (Learning Rate & Gamma):** 1. Add `kDefaultGamma = 0.95` and `kDcnBaselineDrive = 0.5` to `SimulationConstants`. 2. Update `SimulationEngine.tick` and its private helper `_updateWeights` to accept `double learningRate` and `double gamma` as required parameters. 3. Replace the hardcoded `0.95` in `_tdError` and `+0.5` in the DCN current calculation with these parameters. 4. Update `SimulationNotifier._tick()` to read the current value from `learningRateProvider` and pass it into the engine. 5. Add a unit test in `test/simulation_engine_test.dart` verifying that when `learningRate` is `0.0`, `_updateWeights` returns the original synapses unchanged.

- [x] **50. Atomic Research Vault & Stream Safety:** 1. In `VaultNotifier` (`lib/providers/vault_provider.dart`), capture the Firestore `StreamSubscription` in a private variable `_vaultSubscription`. 2. Inside `build()`, cancel any existing subscription before starting a new one and add `ref.onDispose(() => _vaultSubscription?.cancel())`. 3. Refactor `DatabaseService.saveSnapshot` in `lib/services/database_service.dart` to use `FirebaseFirestore.instance.batch()`. 4. The batch must atomically write to both `users/{uid}/snapshots/` and `public_snapshots/` (if `isPublic` is true). 5. Call `await batch.commit().timeout(const Duration(seconds: 10))` and ensure the notifier restores the previous state on error to prevent permanent loading indicators.

- [x] **51. Environment Logic & Punishment Unit Tests:** Create `test/environment_logic_test.dart` to validate the "Teacher" signals driving neural plasticity. 1. **Eyeblink Test:** Verify `punishment` is `1.0` if the US window is reached without a preceding DCN spike, and `0.0` if a spike occurred. 2. **SineWave Test:** Verify punishment is only non-zero when the DCN output direction is opposite to the wave's derivative. 3. **VOR Test:** Verify `imageSlip` correctly incorporates `targetGain` from `VorConfig`. 4. All environment tests must achieve 100% logic coverage before moving to Phase 11.

- [x] **51.5. Firestore Security Rules Audit:** Perform a comprehensive audit of the `firestore.rules` file to transition from Test Mode to Production. 1. Identify all collections, specifically `users/{uid}/snapshots/` and `public_snapshots/`. 2. Verify that the current rules allow read/write access to any unauthenticated user (the vulnerability). 3. Create a `FIRESTORE_RULES.md` at the project root to document the intended logic: users may only read/write their own data, and the public gallery is read-only for others.

- [x] **51.6. Secure Research Vault Implementation:** Deploy strong security rules to the Firebase Console. 1. Implement a rule for `match /users/{userId}/snapshots/{snapshotId}` that only allows `read` and `write` if `request.auth != null && request.auth.uid == userId`. 2. Implement a rule for `match /public_snapshots/{snapshotId}` that allows `read` to any authenticated user but restricts `create` and `delete` to the owner of the snapshot (checking `request.resource.data.userId`). 3. Validate these rules by attempting to read another user's private snapshot via a manual test and confirming a "Permission Denied" error occurs.

- [x] **51.7. Firestore Data Schema Validation:** Update `firestore.rules` to enforce strict data types for the `ExperimentSnapshot` model. 1. Add validation logic ensuring that `synapticWeights` is always a `list` of `float` or `int` types. 2. Enforce that `finalErrorRate` is a `number` between `0.0` and `1.0`. 3. Require that the `taskName` field matches one of the allowed enums: 'eyeblink', 'sineWave', or 'vor'. 4. Validate that `createdAt` is a `timestamp` and matches `request.time` to prevent users from spoofing simulation dates.

- [x] **51.8. Rate Limiting & Resource Protection:** Implement rules to prevent database abuse and spamming in the Research Vault. 1. Limit the creation of snapshots to prevent a single user from flooding the `public_snapshots` gallery (e.g., using a custom function to check recent write timestamps). 2. Add an `allow delete: if false` rule to the `public_snapshots` collection for all users except designated admin UIDs to prevent data loss. 3. Ensure that the `title` field in any new snapshot is a `string` with a length between 3 and 50 characters to maintain gallery quality.

- [x] **51.9. Atomic Batch Verification:** Audit the `DatabaseService.saveSnapshot` method to confirm it correctly utilizes the `WriteBatch` defined in Prompt 50. 1. Verify that the batch logic correctly handles the dual-write to both `users/{uid}/snapshots/` and `public_snapshots/`. 2. Implement a manual test where the second part of the batch is forced to fail (via temporary rule restriction) to confirm that the first write is correctly rolled back. 3. Document the rollback behavior in `FIRESTORE_RULES.md` to ensure future contributors maintain atomicity.

---

## Phase 11: Advanced Analytics & Simulation Control
*This phase introduces long-term convergence tracking to visualize neural learning over time and adds high-speed execution controls for rapid experimentation.*

- [x] **52. Cross-Episode Convergence Model & Provider:** 1. Create `lib/models/episode_record.dart` with `@immutable class EpisodeRecord` holding `int episodeNumber`, `double meanPunishment`, and `double finalTdError`. 2. Create `lib/providers/episode_history_provider.dart` with `EpisodeHistoryNotifier` extending `Notifier<List<EpisodeRecord>>`. 3. `build()` returns `[]`, `recordEpisode()` appends records (limit last 50), and `clear()` resets the list. 4. Expose as `episodeHistoryProvider`. No Flutter dependencies in the model.

- [x] **53. Simulation Heartbeat Integration:** Update `lib/providers/simulation_provider.dart`. 1. Add private fields `_episodePunishmentSum = 0.0` and `_episodeTickCount = 0`. 2. In `_tick()`, increment these by `climbingFiberSignal` and `1` respectively. 3. When `state.episodeCount` increments, construct an `EpisodeRecord` using the previous episode's averages and send to `episodeHistoryProvider`. 4. Reset counters and ensures `resetEpisode()` calls `episodeHistoryProvider.notifier.clear()`.

- [x] **54. Convergence Chart Visualization:** 1. Create `lib/widgets/convergence_chart.dart` as a `ConsumerWidget`. 2. If records < 2, show "Run episodes to see convergence" in muted style; otherwise, render `CustomPaint` with `ConvergenceChartPainter`. 3. Painter draws `meanPunishment` (Red `0xFFE24B4A`) and `finalTdError.abs()` (Cyan `0xFF00FFFF`) on a dark background. 4. Add `ConvergenceChart` to `lib/screens/simulate_screen.dart` below the `SignalPlotter` in a `SizedBox(height: 140)`.

- [x] **55. Simulation Speed & Temporal Control:** 1. Add `kSpeedNormal (1.0)`, `kSpeedFast (5.0)`, and `kSpeedVeryFast (10.0)` to `SimulationConstants`. 2. Refactor `SimulationNotifier` timer logic into `_startTicker()` using a `_speedMultiplier` to adjust `intervalMs`. 3. Implement `pauseSimulation()` (stop timer, keep `episodeStep`) and `resumeSimulation()`. 4. In `SimulateScreen`, replace the play button with a Play/Pause/Resume toggle, a separate Stop button (visible when active/paused), and a `PopupMenuButton` for 1x/5x/10x speed selection.

---

## Phase 12: 3D Visualization & Interactive Projection
*This phase replaces the 2D canvas with a custom 3D engine using isometric projection and perspective math to visualize the crystalline structure of the cerebellum.*

- [x] **56. 3D Projection Math Utilities:** Create `lib/services/neural_3d_projection.dart`. 1. Rules: no Flutter imports, no Riverpod, pure Dart math. 2. Define `@immutable` classes `Offset3D` and `ProjectedPoint`. 3. Implement `Neural3DProjection` with `kNeuronPositions` (biologically-inspired 3D coordinates) and a `project()` method. 4. `project()` must apply X-axis rotation, Y-axis rotation, and perspective divide (`scale = zoom / (z + 4.0)`). 5. Write unit test in `test/neural_3d_projection_test.dart` verifying CF position at zero rotation (expect screenX ≈ 164, screenY ≈ 230 within 5px tolerance).

- [x] **57. Interactive 3D Canvas Widget:** Replace `lib/widgets/neural_canvas.dart` with `NeuralCanvas3D` (ConsumerStatefulWidget). 1. State fields: `_rotX (0.4)`, `_rotY (0.6)`, `_zoom (120.0)`, and `_selectedNeuronId`. 2. Wrap `CustomPaint` in a `GestureDetector` and `ScaleGestureDetector`. 3. Implement rotation logic (`_rotY += delta.dx * 0.008`) and pinch-to-zoom (clamp 60–280). 4. Hit-testing on `onTapUp`: project all neurons and find the nearest within 28px. 5. Use `SingleTickerProviderStateMixin` with an `AnimationController` calling `setState` each tick for smooth 60fps interaction.

- [x] **58. Depth-Sorted 3D Painter:** Create `lib/widgets/neural_canvas_3d_painter.dart`. 1. Draw three horizontal biological layer bands with 40% opacity. 2. **Painter's Algorithm:** Project all neurons and synapses, then sort by depth (furthest first). 3. Draw synapses with alpha-fading: Cyan excitatory, dashed Red inhibitory, width proportional to `weight.abs()`. 4. Draw neurons: scale radius by depth, use cell-type colors. 5. Add a 60% white arc overlay on each neuron circle representing `2π * membranePotential` to visualize live electrical activity.

- [x] **59. Live Neuron Info Overlay:** Create `lib/widgets/neuron_info_overlay.dart`. 1. A `ConsumerWidget` that replaces the bottom sheet with a floating `Positioned` card inside the `NeuralCanvas3D` Stack. 2. Implement "Smart Positioning": card flips to the left if the anchor is near the right edge (width 210px). 3. Display cell name, inhibitory chip, and monospaced rows for Membrane V, Eligibility, Threshold, and Decay. 4. Wrap value text in `AnimatedDefaultTextStyle` (150ms) to pulse the color when `isFiring` is true. 5. Include the one-sentence italicized description from `kCellTypeDescriptions`.

- [x] **60. 3D Engine Integration & Reset Controls:** Update `lib/screens/simulate_screen.dart` to wire the new engine. 1. Replace the 2D canvas reference with `NeuralCanvas3D`. 2. Add a `GlobalKey<NeuralCanvas3DState>` to the widget. 3. Add a floating action Column (bottom-right) with a "Reset View" `IconButton` that calls `currentState?.resetView()` (setting default rotation/zoom) and a "Rotation Hint" button. 4. Run `flutter analyze` and verify the 3D projection updates correctly during 10x simulation speed.

## Phase 13: Engine Optimization (The Performance Fix)
*This phase rewrites the core state structures to eliminate O(N) list traversals, enabling the simulation to scale to hundreds of neurons while strictly maintaining 60fps.*

- [x] **61. State Structure Overhaul:** 1. Read `lib/models/simulation_state.dart`. 2. Refactor the `neurons` property from `final List<NeuronModel> neurons;` to `final Map<String, NeuronModel> neurons;` to enable O(1) lookups by ID. 3. Update the `SimulationState.initial()` factory to map the 5 default neurons by their `id`. 4. Update the constructor, `copyWith`, and `ExperimentSnapshot.fromSimulation` methods accordingly. 5. Run `flutter analyze` and fix all typing errors across providers and painters before proceeding.

- [x] **62. Synapse Indexing (Adjacency List):** 1. Read `lib/models/simulation_state.dart`. 2. Add a new property `final Map<String, List<SynapseModel>> preSynapticIndex;`. 3. This map must group synapses by their `fromNeuronId` to act as an adjacency list for instant outbound connection lookups. 4. Update `initial()` to build this index from the default 4 synapses. 5. Create a helper method `SimulationState rebuildIndex()` that clears and regenerates the index in O(N) time (used only when loading a completely new snapshot from the Vault).

- [x] **63. Engine Tick Optimization:** 1. Read `lib/services/simulation_engine.dart`. 2. Rewrite the `tick()` method to completely eliminate `current.neurons.firstWhere(...)`. 3. In the "Compute Input Currents" phase, iterate over `current.neurons.values`. If a neuron is firing, use `current.preSynapticIndex[n.id]` to instantly find downstream targets and apply the potential, bypassing a full `synapses` list scan. 4. Update `_updateWeights` to utilize `current.neurons[synapse.fromNeuronId]` for O(1) `preNeuron` lookups. 5. Write a unit test in `test/simulation_engine_test.dart` confirming a 100-neuron network processes a tick significantly faster without throwing null or state errors.

## Phase 14: Temporal Dynamics (The Biology Fix)
*This phase introduces ring buffers to model axonal delays, bridging the gap between instantaneous math and the physical reality of parallel fibers.*

- [x] **64. Axonal Delay Models:** 1. Read `lib/models/synapse_model.dart` and `lib/services/network_initializer.dart`. 2. Add `final int axonalDelay;` (default 0) to `SynapseModel`. Update its constructor and `copyWith`. 3. In `NetworkInitializer.createRLMockNetwork()`, assign a random `axonalDelay` between 2 and 5 (representing ticks/frames) to all Excitatory synapses originating from Parallel Fibers (`GC` to `PC`, `BC`, `SC`). 4. Keep all inhibitory synapses (`BC->PC`, `PC->DCN`) at an `axonalDelay` of 0 to represent instantaneous local suppression. 

- [x] **65. Temporal Ring Buffer Implementation:** 1. Read `lib/services/simulation_engine.dart`. 2. Introduce a private `Map<int, Map<String, double>> _potentialBuffer` to schedule future currents. 3. In the `tick` method's propagation phase, instead of immediately adding `(weight * preNeuron.membranePotential)` to the target's current input, push it into `_potentialBuffer[current.episodeStep + s.axonalDelay][s.toNeuronId]`. 4. Update the `lifUpdate` execution to pull accumulated current from `_potentialBuffer[current.episodeStep]` and then delete that key to prevent memory leaks. 5. Write a unit test in `test/simulation_engine_test.dart` asserting that a spike applied at tick 10 on a synapse with an `axonalDelay` of 3 only alters the post-synaptic neuron's potential at tick 13.

## Phase 15: Dynamic Topology & Complex Tasks
*This phase breaks the hardcoded 19-neuron limit, procedurally generates 3D visual layouts, and introduces a complex 2D motor control task.*

- [x] **66. Dynamic Config Object & Wiring:** 1. Create `lib/models/network_config.dart` with an `@immutable class NetworkConfig`. 2. Add fields for `int gcCount`, `int bcCount`, `int pcCount`, `int scCount`, and `int dcnCount`. 3. Add a factory `NetworkConfig.defaultConfig()` returning `(10, 5, 2, 1, 2)`. 4. Update `lib/services/network_initializer.dart` to accept this config object instead of hardcoding loops. 5. Implement probabilistic wiring: use `dart:math` Random so that each `GC` connects to exactly 70% of available `PC`s and `BC`s, ensuring realistic sparsity as the network scales. 

- [x] **67. Procedural 3D Painter:** 1. Read `lib/widgets/neural_canvas_3d_painter.dart`. 2. Remove the static dependency on `Neural3DProjection.kNeuronPositions`. 3. Refactor the projection loop to calculate physical coordinates dynamically based on layer types. 4. Rules: Place `GC`s in a uniformly distributed grid at `Y = -100`, `PC`s evenly spaced in a horizontal row at `Y = 0`, and `DCN`s clustered at `Y = 100`. 5. Use `Random(n.id.hashCode)` to inject a slight positional jitter (±10px) into the coordinates to make the network look organic rather than strictly mechanical. 6. Update `lib/widgets/neural_canvas.dart` to ensure `_handleTapUp` and the overlay tracking in `build` use the same procedural calculation.

- [x] **68. 2D Arm Reaching Environment:** 1. Read `lib/models/cerebellar_task.dart` and add `armReaching` to the enum. 2. Create `lib/services/arm_reaching_environment.dart` implementing `CerebellarEnvironment`. Define the state vector as `[arm_x, arm_y, target_x, target_y]`. 3. Set the continuous punishment signal as the Euclidean distance: `sqrt(pow(target_x - arm_x, 2) + pow(target_y - arm_y, 2))`. 4. Read `lib/services/simulation_engine.dart`. Modify DCN parsing: if the task is `armReaching`, expect 4 DCNs (`x_pos`, `x_neg`, `y_pos`, `y_neg`). 5. Translate their relative firing rates into a 2D velocity vector `(dx, dy)` applied to the arm's position. 6. Output the updated logic and verify with `flutter analyze`.

## Phase 16: Security — Critical Blockers (Production Hardening)

- [x] **69. Bundle ID & Metadata Replacement:** Replace all placeholder bundle identifiers and app metadata across every platform target. Search the entire project for every occurrence of `com.example` and replace with your real reverse-domain bundle ID (e.g. `com.yourdomain.cerebrosim`). Files to update:
  1. `ios/Runner.xcodeproj/project.pbxproj` — update PRODUCT_BUNDLE_IDENTIFIER in all three build configurations (Debug, Release, Profile) for both the Runner and RunnerTests targets.
  2. `ios/Runner/Info.plist` — verify CFBundleIdentifier resolves to the new ID via the xcconfig variable.
  3. `android/app/build.gradle.kts` — update `applicationId`.
  4. `android/app/src/main/AndroidManifest.xml` — update the package attribute if present.
  5. `macos/Runner/Configs/AppInfo.xcconfig` — update PRODUCT_BUNDLE_IDENTIFIER and PRODUCT_NAME.
  6. `macos/Runner.xcodeproj/project.pbxproj` — update both Runner and RunnerTests targets.
  7. `windows/CMakeLists.txt` — update the BINARY_NAME.
  8. `linux/CMakeLists.txt` — update APPLICATION_ID.
  9. `web/manifest.json` — update `name` and `short_name`.
  After updating, run `flutter clean && flutter pub get`. Also update the app display name in `CFBundleDisplayName` (iOS Info.plist) and the android `android:label` to "CerebroSim" (capitalised properly). Run `flutter analyze` — zero errors required before continuing.

- [x] **70. Production Crashlytics:** Add production crash and error reporting using Firebase Crashlytics.
  1. Add `firebase_crashlytics: ^5.0.0` to `pubspec.yaml` under dependencies. Run `flutter pub get`.
  2. In `main.dart`, after `Firebase.initializeApp(...)`, add the following error interception setup:
     - Set `FlutterError.onError` to `FirebaseCrashlytics.instance.recordFlutterFatalError`.
     - Wrap `runApp(...)` in `PlatformDispatcher.instance.onError` to catch async/isolate errors.
     - In debug mode, keep the existing `debugPrint` behavior — only send to Crashlytics in release/profile.
  3. In `SimulationNotifier._tick()`, wrap the entire tick body in a `try/catch`. On catch, call `FirebaseCrashlytics.instance.recordError(e, s, fatal: false)` and call `stopSimulation()` to prevent an infinite error loop.
  4. Add `firebase_crashlytics` to the iOS `Podfile` if not auto-resolved. Verify `GoogleService-Info.plist` (iOS) and `google-services.json` (Android) are present and gitignored.
  5. Replace all remaining `print()` calls across the codebase with `debugPrint()`.
  6. Run `flutter analyze` — zero errors required.

- [x] **71. Unified Network Builder:** There are two competing network builders causing a silent logic bug. `SimulationState.initial()` creates a 5-neuron hardcoded network with IDs like `DCN_01`, while `NetworkInitializer.createRLMockNetwork()` (used by the actual engine) creates a proper network with `dcn_open` and `dcn_close` IDs. Environments (`SineWaveEnvironment`, `VorEnvironment`) silently fall back to `neurons.values.first` when these IDs are missing. Fix as follows:
  1. In `lib/models/simulation_state.dart`, update `SimulationState.initial()` to call `NetworkInitializer.createRLMockNetwork()` instead of hand-building 5 neurons. Remove the hardcoded neuron/synapse construction from `initial()` entirely.
  2. Update the `SimulationState` constructor to keep the `const` keyword only where no factory calls are made. The `initial()` factory no longer needs to be `const`.
  3. In `test/models/simulation_state_test.dart`, update the test assertions to reflect the new 19+ neuron count and the presence of `dcn_open`/`dcn_close` IDs instead of `DCN_01`.
  4. In `test/services/network_initializer_test.dart`, fix the flaky assertions: remove the hardcoded checks for `pc_1 -> dcn_open` and `pc_2 -> dcn_close`. Instead assert: (a) at least one PC->DCN synapse exists; (b) all PC->DCN synapses are inhibitory; (c) neuron counts match the `NetworkConfig.defaultConfig()` values.
  5. Run `flutter test` — all tests must pass.

- [x] **72. Offline Support & Lifecycle Management:** The app fully breaks without internet and the simulation timer keeps running when the app is backgrounded, draining battery. Fix both.
  **Part 1 — Offline support:**
  1. In `main.dart`, after `Firebase.initializeApp(...)`, add: `FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED);`
  2. In `lib/providers/auth_provider.dart`, update `AuthNotifier.build()` to return `FirebaseAuth.instance.currentUser` immediately (already done) — confirm this doesn't suspend on no network.
  3. Add `connectivity_plus: ^6.0.0` to `pubspec.yaml`. Create `lib/providers/connectivity_provider.dart` with a `StreamProvider` that exposes the current connectivity status.
  4. In `lib/screens/app_shell.dart`, watch `connectivityProvider` and show a `MaterialBanner` at the top of the scaffold when offline: "No connection — simulation runs locally, cloud features unavailable." Dismiss automatically when connectivity returns.
  **Part 2 — Background lifecycle:**
  1. In `lib/providers/simulation_provider.dart`, make `SimulationNotifier` implement `WidgetsBindingObserver` (or use `AppLifecycleListener`).
  2. In `build()`, call `WidgetsBinding.instance.addObserver(this)` and cancel in `ref.onDispose(() { WidgetsBinding.instance.removeObserver(this); _timer?.cancel(); })`.
  3. Override `didChangeAppLifecycleState`: on `AppLifecycleState.paused` or `AppLifecycleState.hidden`, call `pauseSimulation()`. On `AppLifecycleState.resumed`, if `_wasRunning` (store this flag before pausing), call `startSimulation()`.
  Run `flutter analyze` — zero errors.

- [x] **73. In-App Account Deletion:** Apple requires in-app account deletion for all apps with user accounts (mandatory since June 2022). Implement a complete delete-account flow.
  1. In `lib/services/auth_service.dart`, add `Future deleteAccount()`:
     - Get the current user: `final user = _auth.currentUser; if (user == null) return;`
     - Delete all Firestore user data using a batch: delete `users/{uid}` document and all documents in `users/{uid}/snapshots/` (fetch them first with `.get()`, then batch delete).
     - Call `await user.delete()` last. If this throws `requires-recent-login`, rethrow so the UI can prompt re-authentication.
     - Also call `await _googleSignIn.signOut()` to clear Google session.
  2. In `lib/providers/auth_provider.dart`, add a `deleteAccount()` method on `AuthNotifier` that sets `AsyncLoading`, calls `authService.deleteAccount()`, and on `requires-recent-login` error, sets a specific `AsyncError` with that code so the UI can handle it distinctly.
  3. In `lib/screens/profile_screen.dart`, add a new `ListTile` below the sign-out tile:
     - Leading icon: `Icons.delete_forever` in `Theme.of(context).colorScheme.error`
     - Title: "Delete account" in `Theme.of(context).colorScheme.error`
     - On tap: show an `AlertDialog` with title "Delete account?", content "This permanently deletes all your experiments and cannot be undone.", actions Cancel and "Delete" (red). On confirm, call `ref.read(authProvider.notifier).deleteAccount()`.
     - If the error code is `requires-recent-login`, show a `SnackBar`: "Please sign out and sign back in before deleting your account."
  4. Run `flutter analyze` — zero errors.

- [x] **74. Buffer Clearing & Email Verification:** Two independent bugs to fix in this prompt.
  **Bug 1 — Plot buffer not cleared on task switch:**
  In `lib/providers/simulation_provider.dart`, update `resetEpisode()` to also clear the plot buffer and episode history:
  - Add `ref.read(plotBufferProvider.notifier).clear();` after `_engine.clearBuffer();`
  - The `episodeHistoryProvider.notifier.clear()` call is already there — confirm it is.
  - In `lib/providers/environment_provider.dart`, `EnvironmentNotifier.selectTask()` calls `ref.read(simulationProvider.notifier).resetEpisode()` — confirm this chain now clears both buffers.
  **Bug 2 — No email verification:**
  1. In `lib/providers/auth_provider.dart`, in `AuthNotifier.register()`, after the successful `registerWithEmail()` call, add: `final user = _auth.currentUser; await user?.sendEmailVerification();`
  2. In `lib/screens/profile_screen.dart`, add a verification banner at the top of the `ListView` that only appears when `user.emailVerified == false`:
     - A `ListTile` with `leading: Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.tertiary)`, title "Email not verified", subtitle "Check your inbox", and a trailing `TextButton("Resend")` that calls `FirebaseAuth.instance.currentUser?.sendEmailVerification()` and shows a `SnackBar("Verification email sent")`.
  3. In `lib/services/database_service.dart`, in `saveSnapshot()`, before the batch commit, check: `if (FirebaseAuth.instance.currentUser?.emailVerified == false) throw 'Please verify your email before saving public experiments.';` — only apply this check when `snap.isPublic == true`.
  Run `flutter analyze` — zero errors.

## Phase 17: Security— Quality & Navigation

- [x] **75. Declarative Routing (GoRouter):** Replace all imperative `Navigator.push`/`pushReplacement`/`pushAndRemoveUntil` calls with declarative `go_router` routing.
  1. Add `go_router: ^14.0.0` to `pubspec.yaml`. Run `flutter pub get`.
  2. Create `lib/router/app_router.dart`. Define a `GoRouter` provider using Riverpod: `final routerProvider = Provider(...)`. The router must have a `refreshListenable` that wraps `authProvider` and `onboardingCompleteProvider` — create a `GoRouterRefreshStream` helper that converts an `AsyncNotifier` to a `ChangeNotifier`.
  3. Define these named routes: `/login`, `/register`, `/onboarding`, `/shell` (with sub-routes `/shell/simulate`, `/shell/vault`, `/shell/profile`).
  4. Add a `redirect` callback:
     - If `authProvider` is loading → return null (show splash).
     - If user is null → redirect to `/login` unless already there.
     - If user is not null and onboarding not complete → redirect to `/onboarding`.
     - If user is not null and onboarding complete → redirect to `/shell/simulate` if currently at `/login` or `/register`.
  5. Replace the `home:` logic in `main.dart`'s `MaterialApp` with `MaterialApp.router(routerConfig: ref.watch(routerProvider))`. Remove the `navigatorKey` and all `ref.listen` navigation logic from `main.dart`.
  6. Update `LoginScreen`, `RegisterScreen`, `OnboardingScreen` to use `context.go(...)` and `context.push(...)` instead of `Navigator`. Remove all `MaterialPageRoute` usages.
  7. Update `AppShell` to use `go_router`'s `ShellRoute` so the bottom nav bar persists across tab navigation.
  8. Run `flutter analyze` and `flutter test` — all tests must pass.

- [x] **76. Native Splash Screen:** Fix the white flash on launch and implement a proper native splash.
  1. Add `flutter_native_splash: ^2.4.0` to `pubspec.yaml` under `dev_dependencies`. Add a `flutter_native_splash` section to `pubspec.yaml`:
     ```yaml
     flutter_native_splash:
       color: "#121212"
       color_dark: "#121212"
       image: assets/splash_logo.png
       fullscreen: true
     ```
     Create a simple `assets/splash_logo.png` (or use the existing app icon). Add `assets/` to the flutter assets section.
  2. Run `dart run flutter_native_splash:create` to generate the native splash assets for iOS, Android, and web.
  3. In `main.dart`, import `flutter_native_splash` and call `FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding)` before `runApp`. Then in `CerebroSimApp`, watch `authProvider` — once it is no longer `AsyncLoading`, call `FlutterNativeSplash.remove()`. This ensures the native splash holds until Firebase auth resolves, eliminating the white flash and the intermediate spinner.
  4. In `main.dart`, remove the `AsyncLoading` → `CircularProgressIndicator` case from the `authState.when(...)` home builder. The native splash now handles that state entirely.
  5. Run `flutter clean && flutter pub get` and verify the splash appears and dismisses correctly on both iOS and Android simulators.

- [ ] **77. Theme Token Audit:** The app has a functioning light theme but numerous widgets use hardcoded `Colors.white`, `Colors.white70`, `Colors.white38`, `Colors.white54`, `Colors.black45` which are invisible in light mode. Replace all of them with theme-aware tokens.
  Perform a full search for `Colors.white` and `Colors.black` in the `lib/` directory. Update every occurrence using this mapping:
  - `Colors.white` (primary text) → `Theme.of(context).colorScheme.onSurface`
  - `Colors.white70` (secondary text) → `Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)`
  - `Colors.white54` (tertiary text) → `Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)`
  - `Colors.white38` (disabled/hint text) → `Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)`
  - `Colors.white24` (dividers) → `Theme.of(context).colorScheme.outline.withValues(alpha: 0.24)`
  - `Colors.white10` (borders) → `Theme.of(context).colorScheme.outline.withValues(alpha: 0.1)`
  - `Colors.white.withValues(alpha: x)` (surface overlays) → `Theme.of(context).colorScheme.onSurface.withValues(alpha: x)`
  - `Colors.black45` (scrim/overlay) → `Theme.of(context).colorScheme.scrim.withValues(alpha: 0.45)`
  - `Colors.black54` (shadow text) → `Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)`
  Files to specifically audit: `lib/widgets/snapshot_card.dart`, `lib/widgets/neuron_detail_sheet.dart`, `lib/widgets/neuron_info_overlay.dart`, `lib/widgets/convergence_chart.dart`, `lib/widgets/signal_plotter.dart`, `lib/widgets/neural_canvas_painter.dart`, `lib/widgets/onboarding/watch_mode_step.dart`, `lib/widgets/onboarding/control_step.dart`, `lib/widgets/onboarding/explore_step.dart`.
  For `CustomPainter` subclasses where `BuildContext` is not available, pass `ColorScheme colorScheme` as a constructor parameter from the parent widget and use it inside `paint()`.
  After updating, manually test by toggling between dark and light modes via the Profile screen. Every screen must be fully readable in both modes. Run `flutter analyze` — zero errors.

- [x] **78. Save State & Vault Filters:** Two UX fixes in one prompt.
  **Part 1 — Save dialog loading state:**
  In `lib/screens/simulate_screen.dart`, in the `_showSaveDialog` bottom sheet:
  1. Add a `bool _isSaving = false` variable inside the `StatefulBuilder`.
  2. When the save button is tapped, immediately call `setState(() => _isSaving = true)` before the `await` call.
  3. Replace the `ElevatedButton`'s child with a ternary: when `_isSaving`, show `SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary))`. When not saving, show `const Text('Save snapshot')`.
  4. Set `onPressed: _isSaving ? null : () { ... }` to prevent double-tap.
  5. Wrap the await in try/finally to reset `_isSaving = false` on both success and error.
  **Part 2 — Vault gallery filter and sort:**
  In `lib/screens/vault_screen.dart`:
  1. Add a `String _filterTask = 'all'` and `String _sortBy = 'date'` to the widget state (convert to `ConsumerStatefulWidget`).
  2. Above the `ListView` in `_buildPublicGallery`, add a horizontal `SingleChildScrollView` with filter chips: "All", "Eyeblink", "Sine", "VOR". Tapping updates `_filterTask` and calls `setState`.
  3. Add a `PopupMenuButton` sort control in the gallery tab's header row with options "Newest first", "Best performance" (sort by `finalErrorRate` ascending).
  4. Apply the filter and sort client-side before passing the list to `ListView.builder`. No new Firestore queries needed.
  5. Apply the same filter chips to the "My Experiments" tab for consistency.
  Run `flutter analyze` — zero errors.

## Phase 18: User Experience— Neuron Count Configurator

- [x] **79. Network Configurator UI:** Allow users to configure the number of each neuron type before running a simulation. This exposes the `NetworkConfig` model that already exists.
  1. Create `lib/providers/network_config_provider.dart`:
     - `NetworkConfigNotifier` extending `Notifier` with `build()` returning `NetworkConfig.defaultConfig()`.
     - Method `update(NetworkConfig c) => state = c`.
     - Expose as `networkConfigProvider`.
  2. Create `lib/screens/network_config_screen.dart` as a `ConsumerWidget`:
     - `AppBar` with title "Network topology" and a reset-to-defaults `IconButton`.
     - A `ListView` with one section per cell type: GC (Granule cells), BC (Basket cells), PC (Purkinje cells), SC (Stellate cells), DCN (Output nuclei).
     - For each type, show a `ListTile` with: the cell type name + a one-line biological role subtitle; a `Row` containing a decrement `IconButton`, the current count in a `SizedBox(width: 40)` `Text`, and an increment `IconButton`.
     - Enforce sensible limits: GC 2–50, BC 1–20, PC 1–10, SC 0–10, DCN 2 (fixed at 2 for standard tasks, shown as read-only with a note "Fixed — required for task environments").
     - Show a live neuron total at the bottom: "Total neurons: N" with a color-coded warning in `colorScheme.error` if N > 30: "Large networks may affect performance at 10x speed."
     - A prominent "Apply & reset simulation" `FilledButton` at the bottom that calls `ref.read(simulationProvider.notifier).resetEpisode(config: ref.read(networkConfigProvider))` and calls `context.go('/shell/simulate')`.
  3. Add a "Configure network" `ListTile` entry to `lib/screens/profile_screen.dart` with `Icons.account_tree` as the leading icon, navigating to `NetworkConfigScreen`.
  4. Run `flutter analyze` — zero errors.

- [x] **80. Configurator Integration:** Connect the network configurator to the full simulation lifecycle so the chosen topology is used everywhere.
  1. In `lib/providers/simulation_provider.dart`, update `SimulationNotifier.build()` to read `networkConfigProvider` and pass it to `_engine.initialState(config: ref.read(networkConfigProvider))`. Add `ref.listen(networkConfigProvider, (_, __) {})` so changes to the config invalidate the notifier correctly — but do NOT auto-reset; only reset when the user explicitly taps "Apply".
  2. In `lib/screens/simulate_screen.dart`, add the current topology summary to the AppBar subtitle or as a small chip row below the task selector: "GC: 10 | BC: 5 | PC: 2 | SC: 1" using the values from `ref.watch(networkConfigProvider)`. Make it a tappable `InkWell` that navigates to `NetworkConfigScreen` so users can reach it without going to Profile.
  3. In `_showSaveDialog`, add the network config to the saved `ExperimentSnapshot`. Update `ExperimentSnapshot` model to include an optional `NetworkConfig? networkConfig` field. Update `toFirestore()` to serialize it as a nested map `{'gcCount': ..., 'bcCount': ...}` and update `fromFirestore()` to deserialize it. Update `ExperimentSnapshot.fromSimulation(...)` to accept and store the config.
  4. In `lib/widgets/snapshot_card.dart`, add a small topology chip below the task chip if `snapshot.networkConfig != null`: e.g. "GC:10 PC:2" in a compact style matching the existing task chip.
  5. In `lib/providers/simulation_provider.dart`, in `loadSnapshot()`, if the snapshot's `networkConfig` is non-null, also update `networkConfigProvider` before rebuilding: `ref.read(networkConfigProvider.notifier).update(snapshot.networkConfig!)`.
  6. Run `flutter analyze` and `flutter test` — all tests must pass.

## Phase 19: User Experience— UI/UX Polish and Layout Fixes

- [x] **81. Simulate Screen Layout Overhaul:** The simulate screen stacks TaskSelector + NeuralCanvas3D + SignalPlotter + ConvergenceChart + FABs in a single Column, causing overflow on smaller devices and visual crowding. Redesign the layout.
  1. Replace the flat `Column` body with a `CustomScrollView` using `SliverList`. Structure:
     - `SliverAppBar` (floating, snap) containing the simulation controls (play/pause/stop/speed/save). Use `backgroundColor: Theme.of(context).colorScheme.surface` with `elevation: 0` and a bottom border.
     - A `SliverToBoxAdapter` for the `TaskSelector` with `16px` vertical padding.
     - A `SliverFillRemaining(hasScrollBody: false)` containing a `Column` with:
       a. `Expanded(flex: 5)` — `NeuralCanvas3D` (takes the majority of screen).
       b. A `Divider(height: 1)`.
       c. `SizedBox(height: 140)` — `SignalPlotter` with internal padding `EdgeInsets.fromLTRB(12, 8, 12, 4)`.
       d. `SizedBox(height: 110)` — `ConvergenceChart` with matching padding.
       e. `SizedBox(height: 16)` — bottom breathing room for nav bar.
  2. Move the FAB column (reset view + hint) to inside the `NeuralCanvas3D` widget's own `Stack`, positioned at `bottom: 8, right: 8` — remove it from `SimulateScreen` entirely. This keeps the FABs visually anchored to the canvas.
  3. Remove the `Stack` wrapper from `SimulateScreen.build()`. The `NeuralCanvas3D` now manages its own overlays internally.
  4. On the AppBar, replace the raw `IconButton` row with a cleaner layout: group play/pause/stop into a single `SegmentedButton`-style widget, and put speed + save as trailing `IconButton`s. This reduces AppBar clutter from 5+ icons to 3 visual units.
  5. Verify on screen sizes: iPhone SE (375×667), standard (390×844), and tablet (768×1024) using `flutter run` device preview. No overflow errors in any layout.
  Run `flutter analyze` — zero errors.

- [x] **82. Chart Axis Labels & Scales:** The convergence chart and signal plotter display data without any reference scale, making them informationally empty. Add axis labels and improve overall chart readability.
  **ConvergenceChartPainter in `lib/widgets/convergence_chart.dart`:**
  1. Reserve `leftMargin = 40.0` and `bottomMargin = 20.0` inside `paint()`. All chart drawing must start at x=leftMargin, y=0 and end at x=size.width, y=size.height-bottomMargin.
  2. Draw 5 horizontal gridlines at Y positions corresponding to values 0.0, 0.25, 0.5, 0.75, 1.0. Use a dashed stroke: `strokeWidth: 0.5`, color `labelStyle.color?.withValues(alpha: 0.2)`.
  3. For each gridline, draw a Y-axis label at x=0, aligned right (`TextPainter` with `textAlign: TextAlign.right`, width=36). Labels: "1.0", "0.75", "0.5", "0.25", "0".
  4. Draw X-axis episode labels: first episode number and last episode number at the bottom margin. Use `labelStyle` at 10px.
  5. Update the legend to also show current values: "Punishment: 0.42" and "|TD error|: 0.18" — read the last record from `history.last`.
  **SignalPlotterPainter in `lib/widgets/signal_plotter.dart`:**
  1. Draw a single horizontal center line (y=0 reference) as a dashed 0.5px line in `colorScheme.outline.withValues(alpha: 0.2)`.
  2. Draw Y-axis tick marks at +1.0 and -1.0 with tiny labels "1" and "-1" at the left edge.
  3. Draw a vertical "now" indicator: a thin vertical line at x=size.width-1 to make it clear the chart scrolls right-to-left.
  Run `flutter analyze` — zero errors.
  1. Draw a single horizontal center line (y=0 reference) as a dashed 0.5px line in `Colors.white24` → replace with `colorScheme.outline.withValues(alpha: 0.2)` after the theme fix prompt.
  2. Draw Y-axis tick marks at +1.0 and -1.0 with tiny labels "1" and "-1" at the left edge.
  3. Draw a vertical "now" indicator: a thin vertical line at x=size.width-1 to make it clear the chart scrolls right-to-left.
  Run `flutter analyze` — zero errors.

- [x] **83. Tactile & Discoverability Polish:** Three tactile and discoverability improvements.
  **Part 1 — Haptic feedback:**
  Add `import 'package:flutter/services.dart'` where needed and add haptic calls:
  - `HapticFeedback.lightImpact()` in `NeuralCanvas3DState._handleTapUp()` when a neuron is found.
  - `HapticFeedback.mediumImpact()` in `SimulationNotifier.startSimulation()`.
  - `HapticFeedback.selectionClick()` in `EnvironmentNotifier.selectTask()` when the task actually changes.
  - `HapticFeedback.lightImpact()` in `VaultNotifier.saveSnapshot()` on success (before the SnackBar).
  **Part 2 — Canvas gesture hint:**
  1. In `lib/services/prefs_service.dart`, add `Future hasSeenCanvasHint()` and `Future setCanvasHintSeen()` using key `'canvas_hint_seen'`.
  2. In `NeuralCanvas3DState.initState()`, check `PrefsService().hasSeenCanvasHint()`. If false, after a 1-second delay show an `OverlayEntry` containing a semi-transparent instruction card: "Swipe to rotate · Pinch to zoom · Tap to inspect" centered over the canvas. Auto-dismiss after 3 seconds or on first touch via `GestureDetector`. On dismiss, call `setCanvasHintSeen()`.
  3. The hint card styling: `Container` with `color: colorScheme.inverseSurface.withValues(alpha: 0.85)`, `borderRadius: BorderRadius.circular(12)`, `padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12)`. Text in `colorScheme.onInverseSurface`.
  **Part 3 — Onboarding resume:**
  In `lib/screens/onboarding_screen.dart`:
  1. In `_OnboardingScreenState.initState()`, read `ref.read(prefsServiceProvider).getOnboardingStep()` (add this method to `PrefsService` using key `'onboarding_step'`, returning an `int` 0-2).
  2. After `_pageController` is created, if the stored step > 0, call `_pageController.jumpToPage(storedStep)` and set `_currentPage = storedStep`.
  3. In `onPageChanged`, call `ref.read(prefsServiceProvider).setOnboardingStep(index)`.
  4. In `_onComplete()`, call `ref.read(prefsServiceProvider).clearOnboardingStep()` before navigating.
  Run `flutter analyze` — zero errors.

- [x] **84. Comprehensive Visual Polish:** A comprehensive visual polish pass to elevate the app from functional to premium. Apply these changes across the entire codebase.
  **ThemeService (`lib/services/theme_service.dart`):**
  1. In `cyberLabTheme`, add: `cardTheme: CardThemeData(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Color(0x1AFFFFFF), width: 0.5)))`.
  2. Add `appBarTheme: AppBarTheme(elevation: 0, scrolledUnderElevation: 0, centerTitle: false, titleTextStyle: GoogleFonts.spaceMono(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF00FFFF)))`.
  3. Add `bottomNavigationBarTheme: BottomNavigationBarThemeData(elevation: 0, backgroundColor: Color(0xFF0A0A0A), selectedItemColor: Color(0xFF00FFFF), unselectedItemColor: Color(0xFF5F5E5A), type: BottomNavigationBarType.fixed)`.
  4. Add `inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Color(0xFF1E1E1E), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0x33FFFFFF), width: 0.5)), contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14))`.
  5. In `presentationTheme`, add matching `cardTheme`, `appBarTheme`, `bottomNavigationBarTheme`, and `inputDecorationTheme` using light-mode appropriate values.
  **SnapshotCard (`lib/widgets/snapshot_card.dart`):**
  - Replace the raw `Card` + `ListTile` with a custom `Container` using the new card theme.
  - Add `12px` vertical and `16px` horizontal padding.
  - Use a two-row layout: top row = title + public badge; bottom row = task chip + episode count + error rate + date.
  - Chips: use `Chip` with `visualDensity: VisualDensity.compact`, `padding: EdgeInsets.zero`, `labelStyle: TextStyle(fontSize: 11)`.
  - Show a `trailing` chevron icon only on wide-enough screens (check `MediaQuery`).
  **TaskSelector (`lib/widgets/task_selector.dart`):**
  - Add `16px` horizontal padding to the `SegmentedButton` wrapper.
  - Set `style: ButtonStyle(minimumSize: WidgetStateProperty.all(Size(0, 40)))` on the `SegmentedButton`.
  - Wrap the `VorConfigPanel` in an `AnimatedSize(duration: Duration(milliseconds: 250), curve: Curves.easeInOut)` so it expands/collapses smoothly.
  **General spacing rules (apply everywhere):**
  - All `ListView` children: minimum `8px` vertical gap between items.
  - All `Column`/`Row` in screens: use `gap` equivalent — replace adjacent `SizedBox` pairs with `mainAxisSpacing` or consistent `SizedBox(height: 16)`.
  - `AppBar` actions: `IconButton` with `visualDensity: VisualDensity.compact` to tighten the tap targets.
  Run `flutter analyze` — zero errors.

- [x] **85. Task Parameter Sliders:** Currently only the VOR task has a config panel. Expose tunable parameters for Eyeblink and Sine Wave to match the educational depth of VOR.
  1. Create `lib/models/eyeblink_config.dart` with `@immutable class EyeblinkConfig`: fields `double csDurationMs` (default 250), `double usDurationMs` (default 50), `double trialDurationS` (default 1.0). Include `copyWith`.
  2. Create `lib/models/sine_config.dart` with `@immutable class SineConfig`: fields `double frequencyHz` (default 1.0), `double amplitude` (default 1.0). Include `copyWith`.
  3. Create providers `eyeblinkConfigProvider` and `sineConfigProvider` as `NotifierProvider`s following the exact same pattern as `vorConfigProvider`.
  4. Update `EyeblinkEnvironment` and `SineWaveEnvironment` constructors to accept their respective config objects. Update `EnvironmentNotifier._buildEnv()` to pass `ref.read(eyeblinkConfigProvider)` and `ref.read(sineConfigProvider)` respectively.
  5. In `lib/widgets/task_selector.dart`, add two new config panel widgets:
     - `EyeblinkConfigPanel`: Two sliders — "CS window" (50ms–500ms, showing value in ms), "Trial duration" (0.5s–3.0s). Status label: "Short CS = harder association" if < 150ms, "Standard Pavlovian timing" otherwise.
     - `SineConfigPanel`: Two sliders — "Frequency" (0.25Hz–4.0Hz), "Amplitude" (0.1–2.0). Status label: "High frequency = rapid adaptation required" if > 2Hz.
  6. Update the `TaskSelector` widget to show the appropriate config panel based on the active task — wrap all three panels in the same `AnimatedSize` pattern used for `VorConfigPanel`.
  7. Run `flutter analyze` — zero errors.

## Phase 20: User Experience— Differentiating Features

- [x] **86. Export & Deep Linking:** Allow researchers to share and export experiments, creating organic virality.
  1. Add `share_plus: ^10.1.4` to `pubspec.yaml`. Run `flutter pub get`.
  2. In `lib/models/experiment_snapshot.dart`, add `String toJson()` that returns a clean JSON string of the snapshot (use `jsonEncode` with all fields except `userId` for privacy). Add `factory ExperimentSnapshot.fromJson(String json)` for import.
  3. In `lib/screens/vault_screen.dart`, add a share `IconButton` to each `SnapshotCard`'s trailing area (in addition to the chevron). On tap:
     - For public snapshots: `Share.share('Check out my CerebroSim experiment: ${snapshot.title}\nTask: ${snapshot.taskName} | Error rate: ${snapshot.finalErrorRate.toStringAsFixed(3)}\ncerebrosim://snapshot/${snapshot.id}')`.
     - For private snapshots: share the JSON export as a file attachment using `Share.shareXFiles([XFile.fromData(utf8.encode(snapshot.toJson()), name: '${snapshot.title}.json', mimeType: 'application/json')])`.
  4. Add deep link handling (URI scheme `cerebrosim://`). In `main.dart`, add `uni_links: ^0.5.1` or use Flutter's built-in `PlatformDispatcher`. Listen for incoming URIs matching `cerebrosim://snapshot/{id}`. On match, navigate to the vault tab and highlight/open the matching snapshot.
  5. Update `ios/Runner/Info.plist` to register the `cerebrosim` URL scheme under `CFBundleURLTypes`. Update `android/app/src/main/AndroidManifest.xml` to register an `intent-filter` for the scheme.
  6. Run `flutter analyze` — zero errors.

- [ ] **87. AI-Powered Interpretation:** Add AI-powered plain-English interpretation of simulation results — the single biggest differentiator versus any competing app.
  IMPORTANT: The API key must never be stored in the client. This feature requires a Firebase Cloud Function as a proxy. If Cloud Functions are not yet set up, stub the HTTP call with a hardcoded response and add a TODO comment.
  1. Create `functions/src/index.ts` (or use existing Cloud Functions setup). Add an HTTPS callable function `interpretExperiment` that:
     - Accepts `{ episodeHistory: EpisodeRecord[], finalErrorRate: number, taskName: string, networkConfig: NetworkConfig }`.
     - Calls the Anthropic Messages API with a system prompt: "You are a neuroscience educator explaining cerebellar learning simulation results to a student. Be concise, specific, and reference real neuroscience (LTD, Purkinje cells, climbing fibers). Maximum 3 paragraphs."
     - Returns `{ interpretation: string }`.
     - Store the Anthropic API key in Firebase environment config, not in code.
  2. In `lib/services/interpretation_service.dart`, create `Future interpretExperiment(...)` that calls the Cloud Function using `FirebaseFunctions.instance.httpsCallable('interpretExperiment').call(data)`.
  3. In `lib/screens/vault_screen.dart`, add an "Interpret" `TextButton` to each snapshot card in the "My Experiments" tab. On tap:
     - Show a `showModalBottomSheet` with a `FutureBuilder` that calls `interpretExperiment`.
     - While loading: `CircularProgressIndicator` centered with text "Analyzing your neural network...".
     - On data: display the interpretation text in a scrollable `Text` widget with `style: Theme.of(context).textTheme.bodyMedium`.
     - On error: show "Interpretation unavailable — check your connection."
  4. Cache the interpretation result in the Firestore snapshot document under field `aiInterpretation` so it only generates once per snapshot.
  5. Run `flutter analyze` — zero errors.

- [ ] **88. Guided Experiments Mode:** Add a "Guided experiments" mode that turns the app into a teaching tool for neuroscience students and professors.
  1. Create `lib/models/guided_experiment.dart` with `@immutable class GuidedExperiment`: fields `String id`, `String title`, `String description`, `String hypothesis`, `List steps` (instruction strings), `NetworkConfig networkConfig`, `CerebellarTask task`, `VorConfig? vorConfig`, `EyeblinkConfig? eyeblinkConfig`, `SineConfig? sineConfig`, `String? paperReference`.
  2. Create `lib/data/guided_experiments.dart` with a `const List kGuidedExperiments` containing at least 4 pre-built experiments:
     - "Pavlovian fear conditioning" (Eyeblink, default config, steps explaining CS-US interval, expected convergence curve, reference to Thompson 1986).
     - "Cerebellar ataxia simulation" (VOR, targetGain: 0.4, steps explaining how low gain models ataxic VOR, reference to Ito 1984).
     - "Gain-up adaptation" (VOR, targetGain: 1.8, steps showing gain-up requiring more episodes, comparing convergence rates).
     - "High-frequency tracking" (SineWave, frequencyHz: 3.0, steps showing how fast signals stress the eligibility trace mechanism).
  3. Create `lib/screens/guided_experiments_screen.dart` as a `ConsumerWidget` displaying the experiments in a `ListView`. Each card shows: title, description preview (2 lines), task chip, paper reference as a tappable link. Tapping opens a detail screen.
  4. Create `lib/screens/guided_experiment_detail_screen.dart` showing the full hypothesis, numbered steps in a `Stepper` widget (can mark each step complete), and a prominent "Run this experiment" `FilledButton` that applies the config and navigates to the simulate screen.
  5. Add a "Guided experiments" entry to `AppShell`'s bottom nav bar OR add it as a `ListTile` in `ProfileScreen` and a banner card at the top of `SimulateScreen`.
  6. Run `flutter analyze` — zero errors.

