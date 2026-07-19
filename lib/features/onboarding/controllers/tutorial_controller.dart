import 'package:get/get.dart';

import '../../../data/repositories/tutorial_progress_repository.dart';
import '../domain/tutorial_lesson_book.dart';
import '../domain/tutorial_step_definition.dart';

// PLACEMENT_NOTE: ARCHITECTURE.md does not yet list onboarding folders; this
// controller coordinates first-time UI guidance without touching game logic.

/// First-time tutorial controller in the GetX UI layer.
class TutorialController extends GetxController {
  /// Creates a tutorial controller backed by [tutorialProgressRepository].
  TutorialController({required this.tutorialProgressRepository});

  /// Repository used to persist seen tutorial keys.
  final TutorialProgressRepository tutorialProgressRepository;

  /// Seen tutorial prompt keys.
  final RxSet<String> seenTutorialKeys = <String>{}.obs;

  /// Tutorial prompt currently being shown.
  final Rxn<TutorialStepDefinition> activeTutorial =
      Rxn<TutorialStepDefinition>();

  /// Whether tutorial progress is loading from persistence.
  final RxBool isLoadingTutorials = false.obs;

  var _hasLoadedTutorialProgress = false;

  /// Loads persisted seen tutorial keys once.
  ///
  /// Inputs: none. Output: completion future. Side effects: reads repository
  /// and updates [seenTutorialKeys].
  Future<void> loadTutorialProgress() async {
    if (_hasLoadedTutorialProgress) {
      return;
    }
    isLoadingTutorials.value = true;
    try {
      final keys = await tutorialProgressRepository.loadSeenTutorialKeys();
      seenTutorialKeys
        ..clear()
        ..addAll(keys);
      _hasLoadedTutorialProgress = true;
    } finally {
      isLoadingTutorials.value = false;
    }
  }

  /// Prepares the tutorial prompt for [levelNumber] when it has not been seen.
  ///
  /// Inputs: one-based level number. Output: active lesson or null. Side
  /// effects: may update [activeTutorial].
  Future<TutorialStepDefinition?> prepareForLevel(int levelNumber) async {
    await loadTutorialProgress();
    final lesson = TutorialLessonBook.lessonForLevel(levelNumber);
    if (lesson == null || seenTutorialKeys.contains(lesson.tutorialKey)) {
      activeTutorial.value = null;
      return null;
    }
    activeTutorial.value = lesson;
    return lesson;
  }

  /// Marks the current tutorial prompt as seen.
  ///
  /// Inputs: none. Output: completion future. Side effects: writes repository
  /// and clears [activeTutorial].
  Future<void> completeActiveTutorial() async {
    final lesson = activeTutorial.value;
    if (lesson == null) {
      return;
    }
    await markTutorialSeen(lesson.tutorialKey);
    activeTutorial.value = null;
  }

  /// Marks [tutorialKey] as seen.
  ///
  /// Inputs: tutorial key. Output: completion future. Side effects: writes
  /// repository and updates [seenTutorialKeys].
  Future<void> markTutorialSeen(String tutorialKey) async {
    if (seenTutorialKeys.contains(tutorialKey)) {
      return;
    }
    seenTutorialKeys.add(tutorialKey);
    await tutorialProgressRepository.markTutorialSeen(tutorialKey);
  }

  /// Marks every V1 tutorial prompt as seen.
  ///
  /// Inputs: none. Output: completion future. Side effects: writes repository
  /// and clears [activeTutorial].
  Future<void> skipAllTutorials() async {
    for (final lesson in TutorialLessonBook.lessons) {
      await markTutorialSeen(lesson.tutorialKey);
    }
    activeTutorial.value = null;
  }
}
