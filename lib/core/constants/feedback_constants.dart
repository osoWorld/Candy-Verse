/// First standard match sound pitch step.
///
/// Source: DESIGN.md §9 — cascade match chime pitches up per combo step.
const double standardMatchBasePlaybackSpeed = 1;

/// Pitch increase per Cascade Step for standard match sound.
///
/// Source: DESIGN.md §9 — each chained match in a cascade pitches up slightly.
const double standardMatchPlaybackSpeedStep = 0.08;

/// Maximum combo step used for standard match pitch reset.
///
/// Source: DESIGN.md §9 — standard match pitch resets at 5 steps.
const int standardMatchPitchResetStepCount = 5;

/// Tempo Meter full haptic duration target.
///
/// Source: DESIGN.md §9 — soft haptic buzz around 40ms on activation.
const int tempoMeterFullHapticMilliseconds = 40;

/// Level complete haptic duration target.
///
/// Source: DESIGN.md §9 — haptics are used for level completion.
const int levelCompleteHapticMilliseconds = 40;
