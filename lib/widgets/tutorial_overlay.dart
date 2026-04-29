import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tutorial_provider.dart';
import '../data/tutorial_steps.dart';

/// A full-screen overlay that displays tutorial steps to the user.
/// Anchored to the bottom 100px to avoid obscuring the primary simulation canvas.
class TutorialOverlay extends ConsumerWidget {
  const TutorialOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStepIndex = ref.watch(tutorialProvider);
    if (currentStepIndex == null) return const SizedBox.shrink();

    final step = kTutorialSteps[currentStepIndex];
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Stack(
      children: [
        // Semi-transparent barrier that ignores touches (allows user to see the UI behind)
        IgnorePointer(
          ignoring: false,
          child: GestureDetector(
            onTap: () => ref.read(tutorialProvider.notifier).dismiss(),
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),
        ),

        // Tutorial Card Positioned at the bottom
        Positioned(
          bottom: 40,
          left: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Step Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(kTutorialSteps.length, (index) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == currentStepIndex
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.2),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // Card content
              Card(
                elevation: 8,
                shadowColor: Colors.black45,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                color: colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(step.icon, color: colorScheme.primary, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Step ${currentStepIndex + 1} of ${kTutorialSteps.length}",
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.secondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  step.title,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        step.description,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                      if (step.actionHint != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.lightbulb_outline, size: 16, color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  step.actionHint!,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => ref.read(tutorialProvider.notifier).dismiss(),
                            child: const Text("Skip"),
                          ),
                          Row(
                            children: [
                              if (currentStepIndex > 0)
                                IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  onPressed: () => ref.read(tutorialProvider.notifier).previousStep(),
                                ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => ref.read(tutorialProvider.notifier).nextStep(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(currentStepIndex == 7 ? "Got it!" : "Next"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
