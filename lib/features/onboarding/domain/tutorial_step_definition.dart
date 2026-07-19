import 'tutorial_target.dart';

/// First-time tutorial prompt definition in the onboarding domain layer.
class TutorialStepDefinition {
  /// Creates one tutorial prompt definition.
  const TutorialStepDefinition({
    required this.tutorialKey,
    required this.levelNumber,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.target,
  });

  /// Stable persistence key for this tutorial prompt.
  final String tutorialKey;

  /// One-based level number that introduces this prompt.
  final int levelNumber;

  /// Short title shown in the tutorial prompt.
  final String title;

  /// Body copy shown in the tutorial prompt.
  final String message;

  /// Primary button label for this prompt.
  final String actionLabel;

  /// Approximate screen area to highlight.
  final TutorialTarget target;
}
