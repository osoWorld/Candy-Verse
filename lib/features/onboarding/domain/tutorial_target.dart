// PLACEMENT_NOTE: ARCHITECTURE.md does not yet list onboarding folders; the
// first-time tutorial shell is isolated under its own feature.

/// Visual target area for a first-time tutorial prompt.
enum TutorialTarget {
  /// Highlight the center board area where swaps happen.
  board,

  /// Highlight the goal and HUD area.
  goal,

  /// Highlight the board area where special candies appear.
  specialCandy,

  /// Highlight the booster tray near the bottom HUD.
  boosterTray,

  /// Highlight blocker and checkpoint learning on the board.
  blocker,
}
