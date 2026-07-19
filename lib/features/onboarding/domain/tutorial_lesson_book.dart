import '../../../core/constants/tutorial_constants.dart';
import 'tutorial_step_definition.dart';
import 'tutorial_target.dart';

/// Provides the V1 first-time tutorial lesson definitions.
class TutorialLessonBook {
  const TutorialLessonBook._();

  /// Ordered tutorial lessons for Sugar Meadow levels 1-5.
  ///
  /// DESIGN_DEFAULT: onboarding copy is V1 implementation copy because the
  /// docs specify tutorial topics but not exact words.
  static const List<TutorialStepDefinition> lessons = [
    TutorialStepDefinition(
      tutorialKey: 'tutorial_level_1_swap',
      levelNumber: 1,
      title: 'Swap to Match',
      message:
          'Trade two neighboring candies to line up three matching Base Candy shapes.',
      actionLabel: 'Start Swapping',
      target: TutorialTarget.board,
    ),
    TutorialStepDefinition(
      tutorialKey: 'tutorial_level_2_cascade',
      levelNumber: 2,
      title: 'Watch the Cascade',
      message:
          'Cleared candies fall, new candies refill from above, and extra matches keep the alchemy rolling.',
      actionLabel: 'Let It Fall',
      target: TutorialTarget.board,
    ),
    TutorialStepDefinition(
      tutorialKey: 'tutorial_level_3_specials',
      levelNumber: 3,
      title: 'Make Special Candies',
      message:
          'Four, five, T, L, and square matches can create striped, wrapped, orb, and charm effects.',
      actionLabel: 'Make Sparks',
      target: TutorialTarget.specialCandy,
    ),
    TutorialStepDefinition(
      tutorialKey: 'tutorial_level_4_boosters',
      levelNumber: 4,
      title: 'Use Boosters',
      message:
          'Choose boosters before Play, then tap a stocked booster in the tray when the board needs help.',
      actionLabel: 'Try the Tray',
      target: TutorialTarget.boosterTray,
    ),
    TutorialStepDefinition(
      tutorialKey: 'tutorial_level_5_blockers',
      levelNumber: 5,
      title: 'Break the Path Open',
      message:
          'Some levels add blockers and checkpoint rewards. Clear the goal, collect stars, and open the next gate.',
      actionLabel: 'Open the Gate',
      target: TutorialTarget.blocker,
    ),
  ];

  /// Returns the tutorial lesson for [levelNumber] when V1 teaches that level.
  ///
  /// Inputs: one-based level number. Output: lesson or null. Side effects:
  /// none.
  static TutorialStepDefinition? lessonForLevel(int levelNumber) {
    if (levelNumber < 1 || levelNumber > tutorialLevelCount) {
      return null;
    }
    for (final lesson in lessons) {
      if (lesson.levelNumber == levelNumber) {
        return lesson;
      }
    }
    return null;
  }
}
