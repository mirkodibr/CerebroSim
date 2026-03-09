# PROMPTS.md: CerebroSim Development Log

**Phase 1: Project Setup & Core Infrastructure**
[x] 1. Read the `REQUIREMENTS.md` file for architectural guardrails
[x] 2. **Dependency Injection:** Add `flutter_riverpod`, `firebase_core`, `firebase_auth`, `cloud_firestore`, and `shared_preferences` to the `pubspec.yaml` file. Ensure all dependencies are compatible with the latest stable Flutter version and run `flutter pub get`.
[x] 3. **Directory Architecture:** Create the following directory structure within the `lib/` folder: `/models`, `/screens`, `/widgets`, `/services`, and `/providers`. Add a placeholder `.gitkeep` file in each to ensure they are tracked by Git.
[x] 4. **Thematic Palette:** Create a file `lib/theme.dart`. Define a `CerebroTheme` class containing a `static ThemeData` object . Use a deep charcoal (#121212) for the primary background and a high-contrast neon cyan (#00E5FF) for primary accents to represent neural activity.
[x] 5. **Scientific Typography:** Update the `ThemeData` in `lib/theme.dart` to include a custom `TextTheme`. Use a clean, sans-serif font optimized for legibility of scientific data and numerical readouts.
[x] 6. **Async Initialization:** Update `main.dart` to make the `main()` function `async`. Add `WidgetsFlutterBinding.ensureInitialized()` and `await Firebase.initializeApp()` to ensure the backend is ready before the app launches. 
[x] 7. **Root ProviderScope:** In `main.dart`, wrap the `CerebroSimApp` widget in a `ProviderScope`. This is the required step to enable Riverpod state management throughout the entire application.
[ ] 8. **Initial Scaffold:** Create `lib/screens/home_screen.dart` with a basic `Scaffold` and a `Center` widget displaying "CerebroSim Initialized". Apply the `ThemeData` defined in Step 3 to the `MaterialApp` in `main.dart`.

**Development Rules**
1. [x]**One Prompt = One Commit:** Always commit the current code and refer to the Prompt # in the commit message before adding a new feature.
2. [x]**No Magic Code:** I am strictly responsible for understanding every line of code generated and must be able to explain it during weekly check-ins.
3. [x]**Refactor Early:** Any file exceeding 200 lines must be broken down into smaller, isolated custom widgets.