/// Expected baseline score one average move can reasonably earn.
///
/// Source: DESIGN_DEFAULT - playtest tooling estimate until real telemetry
/// exists; based on one match plus modest cascade/special value.
const int playtestExpectedScorePerMove = 450;

/// Minimum move limit accepted by the V1 playtest analyzer.
///
/// Source: PRD.md section 9 - levels must have enough moves to resolve goals.
const int playtestMinimumMoveLimit = 5;

/// High blocker density threshold for simple levels.
///
/// Source: DESIGN_DEFAULT - generated level tuning heuristic.
const double playtestSimpleBlockerDensityMax = 0.24;

/// High blocker density threshold for hard levels.
///
/// Source: DESIGN_DEFAULT - generated level tuning heuristic.
const double playtestHardBlockerDensityMax = 0.32;

/// High blocker density threshold for super hard levels.
///
/// Source: DESIGN_DEFAULT - generated level tuning heuristic.
const double playtestSuperHardBlockerDensityMax = 0.38;

/// High blocker density threshold for nightmarishly hard levels.
///
/// Source: DESIGN_DEFAULT - generated level tuning heuristic.
const double playtestNightmareBlockerDensityMax = 0.44;

/// High blocker density threshold for legendary levels.
///
/// Source: DESIGN_DEFAULT - generated level tuning heuristic.
const double playtestLegendaryBlockerDensityMax = 0.5;

/// Early levels are allowed to look easy while onboarding teaches mechanics.
///
/// Source: PRD.md section 6 - Sugar Meadow starts with tutorial tone.
const int playtestTutorialGraceLevelCount = 5;
