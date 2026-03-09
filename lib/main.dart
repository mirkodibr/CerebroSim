import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Start initialization but don't block the UI if it's taking too long
  // or if it's on a platform that isn't configured yet.
  debugPrint("Starting Firebase initialization...");
  
  Firebase.initializeApp().then((_) {
    debugPrint("Firebase initialized successfully.");
  }).catchError((e) {
    debugPrint("Firebase initialization failed: $e");
    debugPrint("App will continue in offline mode.");
  });

  runApp(
    const ProviderScope(
      child: CerebroSimApp(),
    ),
  );
}

class CerebroSimApp extends StatelessWidget {
  const CerebroSimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CerebroSim',
      theme: CerebroTheme.darkTheme,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
