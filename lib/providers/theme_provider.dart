import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

class ThemeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_preference';

  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider).maybeWhen(
      data: (p) => p,
      orElse: () => null,
    );
    
    if (prefs == null) return ThemeMode.dark;
    
    final value = prefs.getString(_key);
    return value == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  Future<void> toggle() async {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = newMode;
    
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_key, newMode == ThemeMode.light ? 'light' : 'dark');
  }
}

final themeNotifierProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});
