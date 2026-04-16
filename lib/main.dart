import 'package:cerebrosim/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/theme_service.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/prefs_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/app_shell.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';

/// The entry point of the CerebroSim application.
///
/// This function handles the initial setup of the application by:
/// 1. Ensuring Flutter framework bindings are initialized.
/// 2. Initializing Firebase with platform-specific options.
/// 3. Setting up Crashlytics for error reporting.
/// 4. Starting the application wrapped in a [ProviderScope] for state management via Riverpod.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    if (kDebugMode) {
      // Force disable Crashlytics collection while doing every day development.
      // Temporarily toggle this to true if you want to test crash reporting in your app.
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
    }
  } catch (e) {
    debugPrint("Firebase/Crashlytics initialization failed: $e");
  }

  runApp(
    const ProviderScope(
      child: CerebroSimApp(),
    ),
  );
}

/// The root widget of the CerebroSim application.
///
/// This [ConsumerStatefulWidget] is responsible for:
/// - Configuring the application-wide theme (light/dark) via [ThemeService] and [themeNotifierProvider].
/// - Managing high-level routing based on the user's authentication state ([authProvider]).
/// - Determining whether to show the [LoginScreen], [OnboardingScreen], or the main [AppShell]
///   based on whether the user is logged in and has completed the onboarding process.
class CerebroSimApp extends ConsumerStatefulWidget {
  const CerebroSimApp({super.key});

  @override
  ConsumerState<CerebroSimApp> createState() => _CerebroSimAppState();
}

class _CerebroSimAppState extends ConsumerState<CerebroSimApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeNotifierProvider);
    final authState = ref.watch(authProvider);

    // Listen for auth state changes to ensure the navigation stack is cleared on sign-out
    ref.listen<AsyncValue<User?>>(authProvider, (previous, next) {
      if (previous?.hasValue == true && previous?.value != null && next.hasValue && next.value == null) {
        _navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    });

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'CerebroSim',
      theme: ThemeService.presentationTheme,
      darkTheme: ThemeService.cyberLabTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      home: authState.when(
        data: (user) {
          if (user == null) return const LoginScreen();
          
          final onboardingComplete = ref.watch(onboardingCompleteProvider);
          return onboardingComplete.when(
            data: (complete) => complete ? const AppShell() : const OnboardingScreen(),
            loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
            error: (e, s) => const AppShell(),
          );
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (e, s) => const LoginScreen(),
      ),
    );
  }
}
