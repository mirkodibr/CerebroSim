import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/prefs_provider.dart';
import '../widgets/onboarding/watch_mode_step.dart';
import '../widgets/onboarding/control_step.dart';
import '../widgets/onboarding/explore_step.dart';
import 'app_shell.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();

  void _onNext() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

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
        children: [
          WatchModeStep(onNext: _onNext),
          ControlStep(onNext: _onNext),
          ExploreStep(onComplete: _onComplete),
        ],
      ),
    );
  }
}
