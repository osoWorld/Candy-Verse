/// Kingdom story panel moment in the Kingdom Map domain layer.
enum KingdomStoryMoment {
  /// Story panel shown when a kingdom begins.
  intro,

  /// Story panel shown when a kingdom is completed.
  outro,
}

/// Returns the storage suffix for [moment].
///
/// Inputs: kingdom story moment. Output: stable storage suffix. Side effects:
/// none.
String kingdomStoryMomentStorageValue(KingdomStoryMoment moment) {
  return switch (moment) {
    KingdomStoryMoment.intro => 'intro',
    KingdomStoryMoment.outro => 'outro',
  };
}
