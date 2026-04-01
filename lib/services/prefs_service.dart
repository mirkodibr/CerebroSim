import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing simple, persistent local settings.
/// 
/// It uses the `shared_preferences` package to store primitive data 
/// types (e.g., bools, strings) on the device across app restarts.
class PrefsService {
  static const _onboardingKey = 'onboarding_complete';

  /// Returns true if the user has completed the initial onboarding experience.
  /// 
  /// Defaults to false if the value has not been set yet.
  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  /// Sets the onboarding completion status to true.
  /// 
  /// This is typically called after the final onboarding step is finished.
  Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  /// Clears the onboarding status from the device's storage.
  /// 
  /// Primarily used for debugging or allowing a user to re-run onboarding.
  Future<void> clearOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingKey);
  }
}
