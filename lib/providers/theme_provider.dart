import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A provider that asynchronously initializes and exposes [SharedPreferences].
/// Used for persisting local application settings like theme preference.
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

/// A notifier that manages the application's [ThemeMode] (light vs dark).
/// It persists the user's choice to local storage using [SharedPreferences].
class ThemeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_preference';

  /// Initializes the theme mode by reading the persisted preference from [SharedPreferences].
  /// Defaults to [ThemeMode.dark] if no preference is found or if storage is not yet available.
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

  /// Toggles between light and dark theme modes and persists the new selection.
  Future<void> toggle() async {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = newMode;
    
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_key, newMode == ThemeMode.light ? 'light' : 'dark');
  }
}

/// A global provider for the [ThemeNotifier].
final themeNotifierProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});
