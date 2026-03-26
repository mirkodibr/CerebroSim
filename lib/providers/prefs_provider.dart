import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/prefs_service.dart';

final prefsServiceProvider = Provider<PrefsService>((ref) {
  return PrefsService();
});

final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  return await ref.read(prefsServiceProvider).isOnboardingComplete();
});
