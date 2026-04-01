import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/prefs_service.dart';

/// A provider that exposes an instance of [PrefsService].
/// This service handles persistent storage of user preferences using shared preferences.
final prefsServiceProvider = Provider<PrefsService>((ref) {
  return PrefsService();
});

/// A future provider that checks if the user has completed the onboarding flow.
/// It queries the [PrefsService] for the completion status.
final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  return await ref.read(prefsServiceProvider).isOnboardingComplete();
});
