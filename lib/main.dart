import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/theme_service.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/prefs_provider.dart';
import 'screens/app_shell.dart';
import 'screens/login_screen.dart';

import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  runApp(
    const ProviderScope(
      child: CerebroSimApp(),
    ),
  );
}

class CerebroSimApp extends ConsumerWidget {
  const CerebroSimApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    final authState = ref.watch(authProvider);

    return MaterialApp(
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
