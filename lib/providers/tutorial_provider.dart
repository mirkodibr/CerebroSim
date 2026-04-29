import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/prefs_provider.dart';

/// Notifier that manages the current step of the in-app tutorial.
/// State is null if the tutorial is inactive, or 0-7 for the current step.
class TutorialNotifier extends Notifier<int?> {
  @override
  int? build() {
    return null;
  }

  /// Starts the tutorial from the first step.
  void startTutorial() {
    state = 0;
  }

  /// Advances to the next step, or dismisses if at the end.
  void nextStep() {
    if (state == null) return;
    if (state! < 7) {
      state = state! + 1;
    } else {
      dismiss();
    }
  }

  /// Goes back to the previous step.
  void previousStep() {
    if (state == null || state == 0) return;
    state = state! - 1;
  }

  /// Dismisses the tutorial and marks it as seen in persistent storage.
  void dismiss() {
    state = null;
    ref.read(prefsServiceProvider).setTutorialSeen();
  }
}

/// A global provider for the [TutorialNotifier].
final tutorialProvider = NotifierProvider<TutorialNotifier, int?>(() {
  return TutorialNotifier();
});
