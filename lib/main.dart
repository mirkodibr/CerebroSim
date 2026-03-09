import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
