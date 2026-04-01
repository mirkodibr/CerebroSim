import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/prefs_provider.dart';
import '../widgets/onboarding/watch_mode_step.dart';
import '../widgets/onboarding/control_step.dart';
import '../widgets/onboarding/explore_step.dart';
import 'app_shell.dart';

/// A multi-step introduction to the CerebroSim simulation environment.
/// 
/// This screen guides new users through the app's core concepts: watching the
/// simulation, controlling its parameters, and exploring different cerebellar tasks.
/// It uses a non-scrollable [PageView] to manage the sequential onboarding steps.
class OnboardingScreen extends ConsumerStatefulWidget {
  /// Creates a new [OnboardingScreen] instance.
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

/// The state for [OnboardingScreen], managing page transitions and completion logic.
class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  /// Controller for the [PageView] that handles navigation between onboarding steps.
  final _pageController = PageController();

  /// Tracks the current step of the onboarding process.
  int _currentPage = 0;

  /// Advances the user to the next step in the onboarding process.
  void _onNext() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Returns the user to the previous step in the onboarding process.
  void _onBack() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Marks onboarding as complete and transitions the user to the [AppShell].
  /// 
  /// This method updates persistent preferences using [prefsServiceProvider] and
  /// invalidates the [onboardingCompleteProvider] to reflect the change globally.
  Future<void> _onComplete() async {
    await ref.read(prefsServiceProvider).setOnboardingComplete();
    ref.invalidate(onboardingCompleteProvider);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AppShell()),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Visibility(
          visible: _currentPage > 0,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
            onPressed: _onBack,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _onComplete,
            child: const Text('Skip', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) => setState(() => _currentPage = index),
        children: [
          WatchModeStep(onNext: _onNext),
          ControlStep(onNext: _onNext),
          ExploreStep(onComplete: _onComplete),
        ],
      ),
    );
  }
}
