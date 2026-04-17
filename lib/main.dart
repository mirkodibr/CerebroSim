import 'dart:async';
import 'package:cerebrosim/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:app_links/app_links.dart';
import 'services/theme_service.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'router/app_router.dart';

/// The entry point of the CerebroSim application.
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

    return DeepLinkHandler(
      child: MaterialApp.router(
        routerConfig: router,
        title: 'CerebroSim',
        theme: ThemeService.presentationTheme,
        darkTheme: ThemeService.cyberLabTheme,
        themeMode: themeMode,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

/// A widget that handles incoming deep links (cerebrosim://).
class DeepLinkHandler extends ConsumerStatefulWidget {
  final Widget child;
  const DeepLinkHandler({super.key, required this.child});

  @override
  ConsumerState<DeepLinkHandler> createState() => _DeepLinkHandlerState();
}

class _DeepLinkHandlerState extends ConsumerState<DeepLinkHandler> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
  if (!kIsWeb) {
    final appLinks = AppLinks();
    
    // Handle the initial link (app opened from closed state)
    try {
      final initialUri = await appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('Failed to get initial link: $e');
    }

    // Listen for links while the app is running
    appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    }, onError: (err) {
      debugPrint('Deep link stream error: $err');
    });
  }
}

  void _handleDeepLink(Uri uri) {
    // Expected: cerebrosim://snapshot/{id}
    if (uri.scheme == 'cerebrosim' && uri.host == 'snapshot') {
      final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      if (id != null) {
        ref.read(routerProvider).go('/shell/vault/$id');
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
