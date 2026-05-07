import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing simple, persistent local settings.
/// 
/// It uses the `shared_preferences` package to store primitive data 
/// types (e.g., bools, strings) on the device across app restarts.
class PrefsService {
  static const _onboardingKey = 'onboarding_complete';
  static const _canvasHintKey = 'canvas_hint_seen';
  static const _onboardingStepKey = 'onboarding_step';
  static const _tutorialSeenKey = 'tutorial_seen';
  static const _disableCelebrationsKey = 'disable_celebrations';

  /// Returns true if the user has completed the initial onboarding experience.
  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  /// Sets the onboarding completion status to true.
  Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  /// Clears the onboarding status from the device's storage.
  Future<void> clearOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingKey);
  }

  /// Returns true if the user has seen the 3D canvas gesture hint.
  Future<bool> hasSeenCanvasHint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_canvasHintKey) ?? false;
  }

  /// Marks the 3D canvas gesture hint as seen.
  Future<void> setCanvasHintSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_canvasHintKey, true);
  }

  /// Returns true if the user has completed the in-app tutorial.
  Future<bool> hasTutorialBeenSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tutorialSeenKey) ?? false;
  }

  /// Records that the user has completed the in-app tutorial.
  Future<void> setTutorialSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialSeenKey, true);
  }

  /// Gets the current onboarding step (0-2).
  Future<int> getOnboardingStep() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_onboardingStepKey) ?? 0;
  }

  /// Sets the current onboarding step.
  Future<void> setOnboardingStep(int step) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_onboardingStepKey, step);
  }

  /// Clears the stored onboarding step.
  Future<void> clearOnboardingStep() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingStepKey);
  }

  /// Returns true when the user has disabled convergence celebration animations.
  Future<bool> isCelebrationDisabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_disableCelebrationsKey) ?? false;
  }

  /// Enables or disables convergence celebration animations.
  Future<void> setCelebrationDisabled(bool disabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_disableCelebrationsKey, disabled);
  }
}
