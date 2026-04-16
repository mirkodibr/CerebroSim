import 'package:cerebrosim/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'services/theme_service.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'router/app_router.dart';

/// The entry point of the CerebroSim application.
///
/// This function handles the initial setup of the application by:
/// 1. Ensuring Flutter framework bindings are initialized.
/// 2. Preserving the native splash screen.
/// 3. Initializing Firebase with platform-specific options.
/// 4. Setting up Crashlytics for error reporting.
/// 5. Enabling Firestore offline persistence.
/// 6. Starting the application wrapped in a [ProviderScope] for state management via Riverpod.
void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Enable Firestore persistence
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
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
/// This [ConsumerWidget] is responsible for:
/// - Configuring the application-wide theme (light/dark) via [ThemeService] and [themeNotifierProvider].
/// - Providing the [GoRouter] configuration from [routerProvider] to the application.
/// - Removing the native splash screen once the initial authentication state is resolved.
class CerebroSimApp extends ConsumerWidget {
  const CerebroSimApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    final router = ref.watch(routerProvider);

    // Remove splash screen once auth state is no longer loading
    ref.listen(authProvider, (previous, next) {
      if (!next.isLoading) {
        FlutterNativeSplash.remove();
      }
    });

    return MaterialApp.router(
      routerConfig: router,
      title: 'CerebroSim',
      theme: ThemeService.presentationTheme,
      darkTheme: ThemeService.cyberLabTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
    );
  }
}
